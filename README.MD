# Docker-Management-Console

### Interactive Docker Management Utility

Program developed by Gustavo Wydler Azuaga - 2025-02-06

## Description

The **Docker Management Console** is a command-line interface (CLI) tool designed to simplify the management of Docker containers and images. This interactive script allows users to build images, run and manage containers, monitor Docker system status, and perform various administrative tasks with ease.

---

## Features

- 🟢 Show Docker images  
- 🐳 Run a container interactively (Persistent mode)  
- 🔗 Attach to a running container  
- 🏗 Build a Docker image from a Dockerfile  
- 📌 Persist changes to a running container into a new image  
- ▶️ Start, stop, and restart containers  
- 📜 View container logs & Docker system logs  
- 🔍 Show detailed Docker info  
- 🚀 Start, stop, and restart the Docker daemon  
- 🗑 Remove images and prune unused resources  
- 🖥 Show running & all containers  

---

## Requirements

- **Docker must be installed** on your system.
  - Install Docker if not installed:
    ```bash
    # Debian-based systems
    sudo apt update && sudo apt install docker.io -y

    # RHEL-based systems (CentOS, AlmaLinux, Rocky Linux)
    sudo yum install -y docker

    # Start Docker daemon if not running
    sudo systemctl start docker
    sudo systemctl enable docker
    ```

---

## How to Run the Program

- **Download the script**:
    ```bash
    git clone https://github.com/kurogane13/docker_interactive_management_console.git
    cd docker_interactive_management_console
    ```

- **Make the script executable**:
    ```bash
    chmod +x docker_console.sh
    ```

- **Run the script**:
    ```bash
    ./docker_console.sh
    ```
