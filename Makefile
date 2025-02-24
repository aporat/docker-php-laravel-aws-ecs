.DEFAULT_GOAL := help

.PHONY: help ps build login-ecr start fresh stop restart destroy ssh migrate migrate-fresh tests cache cache-clear

################################################################################
# Configurable Variables
################################################################################

# Docker Compose service name for the PHP container
CONTAINER_PHP := php

# Name of the AWS Secrets Manager secret holding ECR info
SECRET_ID := php-app

################################################################################
# Help Target
################################################################################
help: ## Print help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

################################################################################
# Docker Compose / ECR Targets
################################################################################
ps: ## Show containers
	@docker compose ps

# We only fetch AWS_REGION, AWS_ACCOUNT_ID, and ECR_BASE_URL inside this target
login-ecr: ## Log in to ECR using AWS CLI & stored secrets
	$(eval AWS_REGION      = $(shell aws secretsmanager get-secret-value --secret-id $(SECRET_ID) --query SecretString | jq -r 'fromjson | .AWS_REGION'))
	$(eval AWS_ACCOUNT_ID  = $(shell aws secretsmanager get-secret-value --secret-id $(SECRET_ID) --query SecretString | jq -r 'fromjson | .AWS_ACCOUNT_ID'))
	$(eval ECR_BASE_URL    = $(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com)

	@echo "Logging in to ECR at $(ECR_BASE_URL)"
	@aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_BASE_URL)

build: ## Build all containers
	@docker compose build
	# Uncomment if you want a fresh build with no cache:
	# @docker compose build --no-cache

start: ## Start containers in the background
	@docker compose up -d

stop: ## Stop running containers
	@docker compose stop

restart: stop start ## Restart containers

fresh: stop build start ## Stop, rebuild, then start containers fresh

destroy: ## Stop and remove containers, networks, volumes
	@docker compose down -v

ssh: ## SSH into PHP container
	@docker exec -it $(CONTAINER_PHP) sh

################################################################################
# Laravel Commands
################################################################################
migrate: ## Run database migrations
	@docker exec $(CONTAINER_PHP) php artisan migrate

migrate-fresh: ## Drop all tables and run all migrations
	@docker exec $(CONTAINER_PHP) php artisan migrate:fresh

tests: ## Run the PHPUnit test suite
	@docker exec $(CONTAINER_PHP) ./vendor/bin/phpunit

cache: ## Cache Laravel configs/routes
	@docker exec $(CONTAINER_PHP) php artisan config:cache; docker exec $(CONTAINER_PHP) php artisan route:cache

cache-clear: ## Clear cached configs/routes
	@docker exec $(CONTAINER_PHP) php artisan config:clear; docker exec $(CONTAINER_PHP) php artisan route:clear
