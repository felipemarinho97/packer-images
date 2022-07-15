# Packer Images

The repo contains the terraform files to create custom AMI's using `packer`.

## Prerequisites

Install packer:

```bash
sudo apt-get install -y packer
```

See: [packer documentation](https://www.packer.io/downloads)

## Base Minimal AMI

This image has the `ami-minimal` group packages and is only 1GB in size. It is done by using `amazon-ebssurrogate` plugin.

To build it, run:

    $ packer build base