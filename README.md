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
- AWS Account (with ECS, ECR, Secrets Manager, CodeBuild permissions)

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

## ECS Deployment Guide (EC2 Launch)

### 1. Clone the Repository

```bash
git clone https://github.com/your-org/your-laravel-repo.git
cd your-laravel-repo
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
4. Name the secret: **php-app**

---

### 5. Create an ECR Repository

1. Go to **ECR > Create Repository**
2. Name it: `php-app`
3. Make it private
4. Save the repository URI

---

### 6. Create an ECS Cluster

1. Go to **ECS > Clusters > Create Cluster**
2. Select **Amazon EC2 instances**
3. Name: `laravel-cluster`
4. **AMI**: Amazon Linux 2 (arm64)
5. Select an **SSH Key Pair**
6. Select your **VPC** and **only public subnets**
7. Click **Create**

---

### 7. Create a Task Definition

1. Go to **Task Definitions > Create**
2. Type: **EC2**
3. Name: `laravel-task`
4. Architecture: **Linux/ARM64**
5. CPU: **1 vCPU**, Memory: **2 GB**

**Add container:**
- Name: `php-laravel`
- Image: your ECR URI
- Port: 80

Click **Create**

---

### 8. Create an ECS Service

1. Open your cluster
2. Go to **Services > Create**

**Settings:**
- Task definition: `laravel-task`, revision `1`
- Service name: `laravel-service`
- Tasks: 1

**Networking:**
- VPC: your VPC
- Subnets: only **public**
- Security group: allow inbound on **port 80**

**Optional Load Balancer:**
- Enable if needed
- Map to port 80

Click **Create Service**

---

### 9. Set Up CI/CD with AWS CodePipeline

1. Go to **CodePipeline > Create pipeline**
2. **Pipeline name**: `laravel-image-build`
3. **Category**: Deployment  
   **Template**: Build a custom pipeline

**Source stage:**
- Provider: GitHub
- Connect your GitHub account and select your repo

**Build stage:**
- Provider: Other build providers → AWS CodeBuild
- Click **Create build project**

**In the modal:**
- Name: `laravel-image-build-project`
- Runtime: Ubuntu Standard (latest)
- Buildspec: Use a buildspec file
- Click **Continue to CodePipeline**

**Test stage**: Skip

**Deploy stage:**
- Provider: Amazon ECS
- Cluster: `laravel-cluster`
- Service: `laravel-service`

Click **Create pipeline**

---

### 10. Configure IAM Permissions for CodeBuild

1. Go to **IAM > Roles**
2. Find: `codebuild-laravel-image-build-project-service-role`
3. Click **Add permissions > Attach policies**
4. Attach these managed policies:
    - `AmazonEC2ContainerRegistryFullAccess`
    - `SecretsManagerReadWrite`

Click **Add permissions**

---

## ✅ Done!

Your Laravel 12 app is now fully Dockerized, deployed to ECS, and automatically built + shipped with every Git push via CodePipeline.
