#!/bin/bash
set -euo pipefail

# ==========================================
# Snipe-IT Deployment on AWS EC2
# Docker + MySQL + AWS Parameter Store
# ==========================================

AWS_REGION="us-east-1"
DEPLOY_DIR="/opt/snipeit"

echo "Starting Snipe-IT deployment..."

# 1. Wait for Docker
echo "Checking Docker..."

until systemctl is-active --quiet docker; do
  sleep 2
done

# 2. Verify Docker Compose
docker compose version

# 3. Verify AWS CLI
aws --version

# 4. Retrieve secrets from AWS Parameter Store
echo "Retrieving secrets from AWS Parameter Store..."

APP_KEY=$(aws ssm get-parameter \
  --name "/snipeit/lab/app-key" \
  --with-decryption \
  --region "$AWS_REGION" \
  --query "Parameter.Value" \
  --output text)

DB_PASSWORD=$(aws ssm get-parameter \
  --name "/snipeit/lab/db-password" \
  --with-decryption \
  --region "$AWS_REGION" \
  --query "Parameter.Value" \
  --output text)

DB_ROOT_PASSWORD=$(aws ssm get-parameter \
  --name "/snipeit/lab/db-root-password" \
  --with-decryption \
  --region "$AWS_REGION" \
  --query "Parameter.Value" \
  --output text)

export APP_KEY DB_PASSWORD DB_ROOT_PASSWORD

echo "Secrets retrieved successfully."

# 5. Get EC2 public IP using IMDSv2
echo "Detecting EC2 public IP..."

TOKEN=$(curl -fsS -X PUT \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
  http://169.254.169.254/latest/api/token)

PUBLIC_IP=$(curl -fsS \
  -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

export APP_URL="http://${PUBLIC_IP}"

echo "Application URL configured."

# 6. Create deployment directory
mkdir -p "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

# 7. Create Docker Compose configuration
cat > docker-compose.yml <<'EOF'
services:

  mysql:
    image: mysql:8.0
    restart: unless-stopped

    environment:
      MYSQL_DATABASE: snipeit
      MYSQL_USER: snipeit
      MYSQL_PASSWORD: ${DB_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}

    volumes:
      - mysql_data:/var/lib/mysql

    healthcheck:
      test:
        - CMD-SHELL
        - MYSQL_PWD="$${MYSQL_ROOT_PASSWORD}" mysqladmin ping -h localhost -u root --silent
      interval: 10s
      timeout: 5s
      retries: 15

  snipeit:
    image: snipe/snipe-it:latest
    restart: unless-stopped

    depends_on:
      mysql:
        condition: service_healthy

    ports:
      - "127.0.0.1:8080:80"

    environment:
      APP_ENV: production
      APP_DEBUG: "false"
      APP_URL: ${APP_URL}
      APP_KEY: ${APP_KEY}

      DB_CONNECTION: mysql
      DB_HOST: mysql
      DB_PORT: "3306"
      DB_DATABASE: snipeit
      DB_USERNAME: snipeit
      DB_PASSWORD: ${DB_PASSWORD}

    volumes:
      - snipeit_data:/var/lib/snipeit

volumes:
  mysql_data:
  snipeit_data:
EOF

# 8. Start containers
echo "Starting MySQL and Snipe-IT..."

docker compose up -d

# 9. Display container status
echo "Checking container status..."

docker compose ps

echo "Snipe-IT deployment completed."
echo "Application URL: $APP_URL"