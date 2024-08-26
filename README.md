# Packer Images

The repo contains the terraform files to create custom AMI's using `packer`.

## Prerequisites

Install packer:

```bash
sudo apt-get install -y packer
```

See: [packer documentation](https://www.packer.io/downloads)

## Base Minimal AMI

This is a _ultra small_ AMI, ocupying only ~600MB of the filesystem. It has a subgroup of `ami-minimal` group packages and it's snapshot is only 1GB in size. It is done by using `amazon-ebssurrogate` plugin.

Initialize the packer configuration:

    $ packer init base

To build it, run:

    $ packer build base

## nvidia-docker AMI

This is an AMI based on "Amazon Linux 2023 Minimal" with Nvidia drivers and Docker installed. It is done by using `amazon-ebs` plugin on top of the `al2023-minimal`.
The snapshot has 4GB in size and the AMI is ~3.5GB.

Initialize the packer configuration:

    $ packer init nvidia-docker

To build it, run:

    $ packer build nvidia-docker