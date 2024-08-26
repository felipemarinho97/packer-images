packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "nvidia-docker"
  spot_instance_types = ["g4dn.xlarge"]
  spot_price    = "0.20"
  region        = "sa-east-1"
  source_ami_filter {
    filters = {
      name                = "al2023-ami-minimal-*-x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  ssh_username = "ec2-user"
  ssh_read_write_timeout = "5m" # Allow reboots
  # shrink root volume to 4GB
  launch_block_device_mappings {
    device_name = "/dev/xvda"
    volume_size = 4
    delete_on_termination = true
  }
}


build {
  name    = "nvidia-docker"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  provisioner "shell" {
    script          = "nvidia-docker/install-dev-kernel.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
    expect_disconnect   = true
  }

  provisioner "shell" {
    script          = "nvidia-docker/install-driver.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean          = true
    expect_disconnect   = true
  }

  provisioner "shell" {
    script          = "nvidia-docker/install-docker.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    
    start_retry_timeout = "5m"
    skip_clean          = true
    expect_disconnect   = true
  }
}