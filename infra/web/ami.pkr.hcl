packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "arm_amazonlinux" {
  ami_name              = "shipvote-arm"
  force_delete_snapshot = "true"
  force_deregister      = "true"
  spot_instance_types   = ["t4g.2xlarge"]
  spot_price            = "auto"
  region                = "eu-central-1"

  source_ami_filter {
    filters = {
      virtualization-type = "hvm"
      name                = "al2023-ami-2023.*.*-kernel-6.1-arm64"
      root-device-type    = "ebs"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  ssh_interface = "public_ip"
  ssh_username  = "ec2-user"

  tags = {
    app  = "shipvote-arm"
    tier = "web"
  }
}

build {
  sources = ["source.amazon-ebs.arm_amazonlinux"]

  provisioner "file" {
    destination = "/tmp/shipvote.service"
    source      = "static/shipvote.service"
  }

  provisioner "file" {
    destination = "/tmp/shipvote_src"
    source      = "../../backend"
  }

  provisioner "file" {
    destination = "/tmp/shipvote.env"
    source      = "static/shipvote.env"
  }

  provisioner "file" {
    destination = "/tmp/tailscale.key"
    source = "static/tailscale.key"
  }

  provisioner "shell" {
    # run as root
    execute_command = "sudo sh -c '{{ .Vars }} {{ .Path }}'"

    scripts = [
      "scripts/setup_dependencies.sh",
      "scripts/setup_service.sh",
      "scripts/setup_source.sh",
      "scripts/build_release.sh",
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
