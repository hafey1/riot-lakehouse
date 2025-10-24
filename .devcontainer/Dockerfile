# .devcontainer/Dockerfile
FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Install dependencies: AWS CLI v2, jq, unzip, git-lfs, terraform
RUN apt-get update && \
    apt-get install -y curl unzip jq git-lfs gnupg software-properties-common && \
    git lfs install && \
    # AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp && /tmp/aws/install && \
    # Terraform
    curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add - && \
    apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main" && \
    apt-get update && apt-get install -y terraform && \
    rm -rf /var/lib/apt/lists/* /tmp/aws /tmp/awscliv2.zip