#!/bin/bash

set -e

# Step 2: Download and install the NVIDIA driver
wget https://us.download.nvidia.com/XFree86/Linux-x86_64/550.90.07/NVIDIA-Linux-x86_64-550.90.07.run
chmod +x NVIDIA-Linux-x86_64-550.90.07.run
sudo ./NVIDIA-Linux-x86_64-550.90.07.run --dkms -s

rm NVIDIA-Linux-x86_64-550.90.07.run
# Step 3: Reboot the instance
sudo reboot
