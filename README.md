# aws-portfolio

> **Un portfolio cloud personnel hébergé et déployé entièrement sur Amazon Web Services (AWS).**

---

## 📋 Description

Ce dépôt contient le code source et la configuration d'infrastructure d'un **portfolio personnel** déployé sur AWS. L'objectif est de démontrer des compétences en développement web et en services cloud AWS, en utilisant une architecture serverless moderne et économique.

---

## 🏗️ Architecture

Le projet s'appuie sur les services AWS suivants :

| Service AWS | Rôle |
|---|---|
| **S3** | Hébergement des fichiers statiques du site (HTML, CSS, JS, images) |
| **CloudFront** | CDN (réseau de diffusion de contenu) pour une distribution globale rapide et sécurisée |
| **Route 53** | Gestion du nom de domaine et des enregistrements DNS |
| **ACM (Certificate Manager)** | Certificat SSL/TLS pour le HTTPS |
| **Lambda** | Fonctions serverless pour la logique back-end (ex : formulaire de contact) |
| **API Gateway** | Point d'entrée HTTP pour les fonctions Lambda |
| **IAM** | Gestion des rôles et permissions |

---

## 📁 Structure du dépôt

```
aws-portfolio/
├── README.md          # Documentation du projet (ce fichier)
```

> Le projet est en cours de développement. Les dossiers de code source et d'infrastructure seront ajoutés prochainement.

---

## 🚀 Déploiement

Le site est déployé de manière statique via **Amazon S3** et distribué grâce à **Amazon CloudFront**. Voici les grandes étapes du déploiement :

1. **Build** — Génération des fichiers statiques du site
2. **Upload S3** — Envoi des fichiers dans un bucket S3 configuré pour l'hébergement web
3. **Invalidation CloudFront** — Mise à jour du cache CDN pour refléter les nouveaux fichiers
4. **DNS** — Le nom de domaine pointe vers la distribution CloudFront via Route 53

---

## 🛠️ Prérequis

- Un compte AWS avec les permissions nécessaires
- [AWS CLI](https://aws.amazon.com/cli/) configuré localement
- [Node.js](https://nodejs.org/) (si un framework front-end est utilisé)

---

## 👤 Auteur

**HermannDj**  
[GitHub](https://github.com/HermannDj)

---

## 📄 Licence

Ce projet est à usage personnel et éducatif.
