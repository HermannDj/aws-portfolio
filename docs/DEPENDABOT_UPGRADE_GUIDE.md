# Guide de Migration Dependabot - Providers Terraform

## ⚠️ Mises à jour majeures en attente

### 1. Helm Provider: v2.12 → v3.1 (PR #21)

**Breaking Changes:**
- Migration vers `terraform-plugin-framework`
- Changements potentiels dans la gestion des releases

**Actions requises:**
1. Vérifier les ressources `helm_release` existantes
2. Tester `terraform plan` localement
3. Valider que les releases Helm existantes ne sont pas impactées

**Commande de test:**
```bash
cd projects/architect-blueprint
terraform init -upgrade
terraform plan
```

---

### 2. AWS Provider: v5.40 → v6.34 (PR #18)

**Breaking Changes:**
- Version majeure 6.x avec changements d'API
- Nouvelles ressources et dépréciations possibles

**Actions requises:**
1. Consulter le changelog: https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md
2. Vérifier les ressources AWS utilisées dans le projet
3. Tester le plan Terraform

**Risques:**
- Changements dans les attributs de ressources existantes
- Nouveaux requis ou validations

---

### 3. Kubernetes Provider: v2.27 → v3.0 (PR #15)

**Breaking Changes:**
- Dépréciation des ressources non-versionnées
- Migration Kubernetes v1.33
- Nouvelles contraintes de validation

**Ressources à mettre à jour:**
- `kubernetes_deployment` → `kubernetes_deployment_v1`
- `kubernetes_service` → `kubernetes_service_v1`
- `kubernetes_config_map` → `kubernetes_config_map_v1`
- etc.

**Actions requises:**
1. Identifier toutes les ressources Kubernetes utilisées
2. Renommer vers les versions `_v1`
3. Tester le plan

---

## 🚀 Procédure de validation

Pour chaque PR:

1. **Merger la PR de fix de workflows en premier**
2. **Tester localement:**
   ```bash
   git checkout [branche-dependabot]
   cd projects/architect-blueprint
   terraform init -upgrade
   terraform plan
   ```
3. **Si le plan est clean:** Merger la PR Dependabot
4. **Si erreurs:** Créer une PR de migration du code Terraform

---

## 📊 Ordre de merge recommandé

1. ✅ **Fix workflows PR** (workflows CI/CD)
2. 🟡 **PR #15** (Kubernetes v3.0) - Plus de breaking changes
3. 🟡 **PR #18** (AWS v6.34) - Impacte le plus de ressources
4. 🟡 **PR #21** (Helm v3.1) - Moins d'impact

---

## 🔗 Références

- PR #21 (Helm): https://github.com/HermannDj/aws-portfolio/pull/21
- PR #18 (AWS): https://github.com/HermannDj/aws-portfolio/pull/18
- PR #15 (Kubernetes): https://github.com/HermannDj/aws-portfolio/pull/15
