packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebssurrogate" "minimal-amd64" {
  ami_name      = "base-minimal"
  instance_type = "t2.micro"
  region        = "us-east-1"
  ami_virtualization_type = "hvm"
  source_ami_filter {
    filters = {
      name                = "al2022-ami-minimal-*x86_64"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  launch_block_device_mappings {
      volume_type = "standard"
      device_name = "/dev/xvdf"
      delete_on_termination = true
      volume_size = 1
  }

  ami_root_device {
    source_device_name = "/dev/xvdf"
    device_name = "/dev/xvda"
    delete_on_termination = true
    volume_size = 6
    volume_type = "gp2"
  }

  ssh_username = "ec2-user"
}


build {
  name    = "base-minimal"
  sources = [
    "source.amazon-ebssurrogate.minimal-amd64"
  ]

  provisioner "shell" {
    script = "base/chroot-bootstrap.sh"
    execute_command = "sudo -S sh -c '{{ .Vars }} {{ .Path }}'"

    start_retry_timeout = "5m"
    skip_clean = true
  }
}
