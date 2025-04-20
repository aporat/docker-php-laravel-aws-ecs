# Laravel on AWS ECS (EC2)

This project demonstrates how to deploy a **Laravel 12** application to AWS ECS using Docker, with a robust local development environment and CI/CD via AWS CodeBuild.

## Local Development Environment

**Stack:**
- Laravel: 12.x
- PHP: 8.4.x
- MySQL: 8.0.x
- phpMyAdmin: 5.x
- Redis: 7.x
- Mailpit: 1.x

### Prerequisites

- Docker & Docker Compose
- PHP 8.4+ with Composer
- AWS CLI
- AWS Account

### Getting Started

```bash
make create-project   # Creates a Laravel 12 app
make build            # Builds Docker images
make start            # Starts containers
```

**Local URLs:**

- App: http://localhost
- Mailpit: http://localhost:8025
- phpMyAdmin: http://localhost:8080

---

## ECS Deployment Guide

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/your-laravel-repo.git
```

---

### 2. Configure AWS CLI

```bash
aws configure
```

---

### 3. Create or Confirm a VPC

Ensure a VPC exists with **only public subnets**. Create one in the **VPC Console** if needed.

---

### 4. Store AWS Info in Secrets Manager

1. Go to **Secrets Manager > Store a new secret**
2. Choose **Other type of secret** → **Plaintext**
3. Use this value:
   ```json
   {
     "AWS_REGION": "us-east-1",
     "AWS_ACCOUNT_ID": "your-account-id"
   }
   ```
4. Name the secret: **laravel-app**

---

### 5. Create an ECR Repository

1. Go to **ECR > Create Repository**
2. Name it: `laravel-app`
3. Save the repository URI

---

### 6. Create an ECS Cluster

1. Go to **ECS > Clusters > Create Cluster**
2. Select **Amazon EC2 instances**
3. Name: `laravel-cluster`
4. **AMI**: Amazon Linux 2 (arm64)
5. **EC2 instance type**: t4f.large
6. Select an **SSH Key Pair**
7. Select your **VPC** and **only public subnets**
8. Click **Create**

---

### 7. Create a Task Definition

1. Go to **Task Definitions > Create**
2. Name: `laravel-task`
3. Infrastructure requirements: **Amazon EC2 instances**
4. Operating system/Architecture: **Linux/ARM64**
4. Network mode: **bridge**
5. CPU: **1 vCPU**, Memory: **2 GB**

**Add container:**
- Name: `laravel-app`
- Image: your ECR URI:lastest, for example: 7390159161217.dkr.ecr.us-east-1.amazonaws.com/laravel-app:latest 
- Port: 80

Click **Create**

---

### 8. Create an ECS Service

1. Open your cluster
2. Go to **Services > Create**

**Settings:**
- Task definition family: `laravel-task`, revision `1`
- Service name: `laravel-service`

Click **Create Service**

---

### 9. Set Up CI/CD with AWS CodePipeline

1. Go to **CodePipeline > Create pipeline**
2. **Category**: Build a custom pipeline
3. **Pipeline name**: `laravel-image-build`

**Source stage:**
- Provider: GitHub
- Connect your GitHub account and select your repo

**Build stage:**
- Provider: Other build providers → AWS CodeBuild
- Click **Create build project**

**In the modal:**
- Name: `laravel-app-image-build-project`
- Operating System: Amazon Linux
- Image: aws/codebuild/amazonlinux2-aarch64-standard:3.0
- Buildspec: Use a buildspec file
- Click **Continue to CodePipeline**

**Test stage**: Skip

**Deploy stage:**
- Provider: Amazon ECS
- Cluster: `laravel-cluster`
- Service: `laravel-service`
- Image definitions file - **imagedefinitions.json**

Click **Create pipeline**

---

### 10. Configure IAM Permissions for CodeBuild

1. Go to **IAM > Roles**
2. Find: `laravel-app-image-build-project-service-role`
3. Click **Add permissions > Attach policies**
4. Attach these managed policies:
    - `AmazonEC2ContainerRegistryFullAccess`
    - `SecretsManagerReadWrite`

Click **Add permissions**

---

## ✅ Done!

Your Laravel app is now fully Dockerized, deployed to ECS, and automatically built + shipped with every Git push via CodePipeline.
