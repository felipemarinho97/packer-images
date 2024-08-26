#!/bin/bash

set -e

# Step-by-Step Installation Guide

# Step 0: Remove existing NVIDIA drivers and CUDA installations
sudo yum erase -y nvidia cuda

# Step 1: Update the system and install dependencies
sudo yum update -y
sudo yum groupinstall -y "Development Tools"
sudo yum install -y kernel-devel-$(uname -r) kernel-headers-$(uname -r) dkms kernel-modules-extra wget

# Step X: Blacklist the nouveau driver === PROBABLY NOT NEEDED, Step 2.5 is needed instead
# sudo bash -c 'echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf'
# sudo bash -c 'echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nouveau.conf'
# sudo dracut --force

sudo reboot
