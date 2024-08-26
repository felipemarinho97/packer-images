#!/bin/bash

set -e

# Step 4: Verify the installation
# After reboot, you can run the following command to verify the installation
nvidia-smi

# Step 5: Install Docker
sudo yum update -y
sudo yum install -y docker
sudo service docker start
sudo usermod -a -G docker ec2-user

docker info

# Step 6: Install NVIDIA Container Toolkit

## Set up the package repository and GPG key:
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo yum clean expire-cache
sudo yum update -y

## Install the NVIDIA Container Toolkit:
sudo yum install -y nvidia-container-toolkit

## clean up yum cache
sudo yum clean all
sudo dnf clean all

## Restart the Docker daemon to complete the installation:
sudo systemctl restart docker
