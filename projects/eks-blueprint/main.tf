# ---------------------------------------------------------------------------
# AWS Load Balancer Controller (Helm)
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "lbc" {
  metadata {
    name = "kube-system"
    # namespace already exists; we reference it to make the dependency explicit
  }
  lifecycle {
    ignore_changes = [metadata]
  }
}

resource "helm_release" "aws_lbc" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.lbc_chart_version
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = aws_eks_cluster.main.name
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lbc.arn
  }

  set {
    name  = "region"
    value = var.aws_region
  }

  set {
    name  = "vpcId"
    value = aws_vpc.main.id
  }

  depends_on = [
    aws_eks_node_group.main,
    aws_iam_role_policy_attachment.lbc,
  ]
}

# ---------------------------------------------------------------------------
# Sample workload namespace
# ---------------------------------------------------------------------------
resource "kubernetes_namespace" "sample" {
  metadata {
    name = "sample-app"
    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  depends_on = [aws_eks_node_group.main]
}

# ---------------------------------------------------------------------------
# Sample nginx Deployment
# ---------------------------------------------------------------------------
resource "kubernetes_deployment" "sample" {
  metadata {
    name      = "sample-nginx"
    namespace = kubernetes_namespace.sample.metadata[0].name
    labels = {
      app = "sample-nginx"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "sample-nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "sample-nginx"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginx:1.27"

          port {
            container_port = 80
            protocol       = "TCP"
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.aws_lbc]
}

# ---------------------------------------------------------------------------
# Sample Service (NodePort for ALB target)
# ---------------------------------------------------------------------------
resource "kubernetes_service" "sample" {
  metadata {
    name      = "sample-nginx"
    namespace = kubernetes_namespace.sample.metadata[0].name
    labels = {
      app = "sample-nginx"
    }
  }

  spec {
    selector = {
      app = "sample-nginx"
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }

    type = "NodePort"
  }

  depends_on = [kubernetes_deployment.sample]
}

# ---------------------------------------------------------------------------
# Sample Ingress (ALB via AWS Load Balancer Controller)
# ---------------------------------------------------------------------------
resource "kubernetes_ingress_v1" "sample" {
  metadata {
    name      = "sample-nginx"
    namespace = kubernetes_namespace.sample.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"                = "alb"
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}]"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    }
  }

  spec {
    rule {
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.sample.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_service.sample,
    helm_release.aws_lbc,
  ]
}
