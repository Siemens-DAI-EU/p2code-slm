#!/bin/bash
set -e

# GitLab CE + Docker + GitLab Runner + Container Registry
# Installation and configuration script

echo ">>> Updating package index..."
sudo apt-get update

# Install required packages for GitLab installation and email functionality
# curl: used for fetching GitLab setup scripts
# openssh-server: required for Git over SSH
# ca-certificates: ensures secure HTTPS communication
# tzdata: provides timezone data for consistent timestamps
# perl: required by some GitLab and system scripts
# postfix and mailutils: enable email notifications from GitLab
sudo apt-get install -y curl openssh-server ca-certificates tzdata perl postfix mailutils

echo ">>> Adding the GitLab CE package repository..."
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

echo ">>> Installing GitLab CE..."
sudo EXTERNAL_URL="https://gitlab.incode.daiconro.eu" apt-get install -y gitlab-ce

# Install Docker (needed for container registry support and Docker-based runners)

echo ">>> Installing Docker prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

echo ">>> Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo ">>> Adding the Docker repository..."
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ">>> Installing Docker packages..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Install GitLab Runner

echo ">>> Adding the GitLab Runner repository..."
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

echo ">>> Installing GitLab Runner..."
sudo apt-get install -y gitlab-runner

# Configure the GitLab Container Registry 

echo ">>> Configuring the GitLab container registry..."

GITLAB_RB="/etc/gitlab/gitlab.rb"

# Configure the main GitLab external URL
sudo sed -i "s|^external_url .*|external_url 'https://gitlab.incode.daiconro.eu'|" $GITLAB_RB

# Remove older or duplicated registry configuration lines
sudo sed -i "/^registry_external_url/d" $GITLAB_RB
sudo sed -i "/^registry_nginx/d" $GITLAB_RB
sudo sed -i "/^nginx\['listen_port'\]/d" $GITLAB_RB
sudo sed -i "/^nginx\['listen_https'\]/d" $GITLAB_RB

# Append registry configuration
cat <<EOF | sudo tee -a $GITLAB_RB

# GitLab container registry settings
registry_external_url 'https://registry.incode.daiconro.eu'

nginx['listen_port'] = 80
nginx['listen_https'] = false

registry_nginx['listen_port'] = 4567
registry_nginx['listen_https'] = false
EOF

echo ">>> Applying configuration changes..."
sudo gitlab-ctl reconfigure

# Register the GitLab Runner 

echo ">>> Registering the GitLab Runner..."
sudo gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.incode.daiconro.eu/" \
  --registration-token "<token>" \
  --executor "docker" \
  --docker-image alpine:latest \
  --description "docker-runner" \
  --tag-list "incode-docker-runner"

echo ">>> Installation complete!"
echo "GitLab CE, Docker, GitLab Runner, and the container registry are now configured."