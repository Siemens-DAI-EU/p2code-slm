
# Software Lifecycle Management - P2CODE GitLab 

## Overview 
The Software Lifecycle Management (SLM) component of the P2CODE platform is designed to provide a comprehensive and integrated approach to managing the entire lifecycle of software applications across the IoT-Edge-Cloud continuum. The SLM allows microservice developers to continuously integrate and deploy their software, thereby delivering quick features, additions and updates to production deployments.
The Software Lifecycle Management Component is built upon a self-managed GitLab instance, 
providing a powerful and flexible DevOps platform, that facilitates source code management, 
Continuous Integration/Continuous Deployment (CI/CD), and other critical development 
processes into a unified interface.

This repository provides scripts to set up:

1. A **GitLab CE** server with Docker and the container registry configured.
2. A separate **GitLab Runner** on IDP machine with Docker and a registered Shell (or Docker) executor.

Both scripts target **Ubuntu** running on **AWS EC2**.

## Architecture

- **EC2 #1 — GitLab Server**  
  Installs **GitLab CE (Omnibus)** with `EXTERNAL_URL`, configures **Container Registry**, and installs **Docker** (used for registry and potential local builds).

- **EC2 #2 — GitLab Runner**  
  Installs **Docker** and **GitLab Runner**, then **registers the runner** (Shell executor by default).


## Prerequisites

### AWS / EC2
- **AMI**: Ubuntu LTS (20.04 or 22.04 recommended)
- **Instance sizes**:
  - GitLab Server: **t3a.xlarge** 
  - Runner: **t3.large** 
- **Disk**:
  - Server: **≥ 100 GiB** (in practice this grew to ~300 GiB as the Container Registry and large CI/CD artifacts accumulated)
  - Runner: **≥ 50 GiB** 

### OS / Access
- Ubuntu user with `sudo` privileges
- Internet access to `apt`, Docker, and GitLab package repos

### Values to Customize
- **Server script** (`install_gitlab.sh`)
  - `EXTERNAL_URL` (e.g., `https://gitlab.incode.daiconro.eu/`)
  - Registry values in `/etc/gitlab/gitlab.rb`:
    - `registry_external_url` (e.g., `https://registry.incode.daiconro.eu`)
    - `registry_nginx['listen_port']`, etc., as needed
- **Runner script** (`install_gitlab_runner.sh`)
  - `--url` (your GitLab URL)
  - `--registration-token` (from GitLab → Admin/Project → Runners)
  - `--executor` (`shell` or `docker`)


### Domain & TLS Certificate 
A valid TLS certificate must exist for the following domains:

- `gitlab.incode.daiconro.eu`
- `registry.incode.daiconro.eu`

## Scripts Overview

### `install_gitlab.sh` (P2CODE GitLab)
- Updates and installs prerequisites
- Adds GitLab APT repo and installs **gitlab-ce**
- Installs **Docker** (Engine, CLI, Buildx, Compose plugin)
- Configures **Container Registry** in `/etc/gitlab/gitlab.rb`
- Runs `gitlab-ctl reconfigure`
- (Optional) Registers a runner on the server 

> Edit the script to set your `EXTERNAL_URL` and registry values before running.

### `install_gitlab_runner.sh` (P2CODE Runner on IDP)
- Installs **Docker**
- Installs **GitLab Runner**
- Registers the runner **non-interactively** (Shell executor by default)
- Adds `gitlab-runner` to the `docker` group (enables Docker usage in jobs when needed)

> Edit the script to set your `--url`, `--registration-token`, executor, and tags.



## How to Use

> Replace placeholders (domains, tokens) and run as a user with `sudo`.

### A) P2CODE GitLab Instance

1. **Copy script**
   ```bash
   scp install_gitlab.sh ubuntu@<gitlab-server-ip>:/home/ubuntu/
   ```

2. **Run script**
   ```bash
   ssh ubuntu@<gitlab-server-ip>
   sudo chmod +x install_gitlab.sh
   sudo ./install_gitlab.sh
   ```

### B) GitLab Runner Instance

1. **Copy script**
   ```bash
   scp install_gitlab_runner.sh ubuntu@<runner-ip>:/home/ubuntu/
   ```

2. **Run script**
   ```bash
   ssh ubuntu@<runner-ip>
   sudo chmod +x install_gitlab_runner.sh
   sudo ./install_gitlab_runner.sh
   ```

3. **Verify in GitLab**
   - Project (or Admin) → **CI/CD → Runners**  
   - The runner should appear as **online** with your description and tags.


## Post-Install Verification

**On the GitLab Server:**
```bash
sudo gitlab-ctl status
sudo gitlab-ctl tail
```

**On the Runner Node:**
```bash
systemctl status gitlab-runner --no-pager
sudo -u gitlab-runner gitlab-runner verify
```

## Acknowledgments
This work is partially supported by the following EU grants (most recent first):
    EU Horizon Europe P2CODE 101093069.




