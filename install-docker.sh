#!/bin/bash
set -e

# Install Docker
dnf install -y docker

# Enable and start Docker
systemctl enable --now docker

# Install Docker Compose plugin
ARCH=$(uname -m)
mkdir -p /usr/local/lib/docker/cli-plugins

curl -fSL \
  "https://github.com/docker/compose/releases/download/v2.39.4/docker-compose-linux-${ARCH}" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose

chmod +x /usr/local/lib/docker/cli-plugins/docker-compose