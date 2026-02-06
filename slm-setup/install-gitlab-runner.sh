#!/bin/bash
set -e

# GitLab Runner on IDP Machine Setup Script
# Includes Docker installation + GitLab Runner installation and registration

echo ">>> Updating package index..."
sudo apt-get update

# Install Docker

echo ">>> Installing Docker dependencies..."
sudo apt-get install -y ca-certificates curl gnupg

echo ">>> Adding Docker's official GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo ">>> Adding Docker repository..."
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo ">>> Installing Docker packages..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo ">>> Testing Docker installation..."
sudo docker run --rm hello-world || echo "Docker test failed. Continuing."

# Install GitLab Runner

echo ">>> Adding GitLab Runner repository..."
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" \
    | sudo bash

echo ">>> Installing GitLab Runner..."
sudo apt-get install -y gitlab-runner

echo ">>> Checking GitLab Runner service status..."
sudo systemctl status gitlab-runner --no-pager || true

# Register GitLab Runner (shell executor)

echo ">>> Registering GitLab Runner..."
sudo gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.incode.daiconro.eu/" \
  --registration-token "<token>" \
  --executor "shell" \
  --description "incode-shell-runner" \
  --tag-list "incode-shell"

echo ">>> GitLab Runner registration complete."

# Add GitLab Runner to Docker group (allows docker commands inside jobs)

echo ">>> Adding gitlab-runner user to the docker group..."
sudo usermod -aG docker gitlab-runner

echo ">>> Runner will need a logout/login or reboot for group permissions."

echo ">>> Setup complete!"
echo "GitLab Runner on IDP machine is now ready."
``