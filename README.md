# Docker Laravel on AWS Elastic Container Service (ECS)

# Local Development Environment
- Laravel v11.x
- PHP v8.4.x
- MySQL v8.1.x
- phpMyAdmin v5.x
- Mailpit v1.x
- Redis v7.2.x

# Requirements
- Stable version of [Docker](https://docs.docker.com/engine/install/)
- Compatible version of [Docker Compose](https://docs.docker.com/compose/install/#install-compose)
- PHP 8.x with Composer installed locally

# Development Environment Installation

### Create Laravel project
Download the Laravel installer package
```
composer global require "laravel/installer"
```

Create a new Laravel project named "laravel"

```
composer create-project --prefer-dist laravel/laravel laravel
```

Setup the Laravel environment
```
cp .env laravel/.env
```

### Docker Setup
Build the docker images
```
make build
```

Start the containers
```
make start
```

### Laravel App
- URL: http://localhost

### Mailpit
- URL: http://localhost:8025

### phpMyAdmin
- URL: http://localhost:8080
