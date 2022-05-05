terraform {
  required_providers {
    banyan = {
      source  = "banyansecurity/banyan"
      version = "0.6.3"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    time = {
      source = "hashicorp/time"
      version = "0.7.2"
    }
  }
}

provider "aws" {
  region = var.region
  profile = var.profile
}

provider "banyan" {
  api_token = var.banyan_api_key
  host      = var.banyan_host
}

locals {
  tags = merge(var.tags, {
    Provider = "Banyan"
    Name = "${var.connector_name}"
  })
}

data aws_ami "default_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.default_ami_name]
  }
}


resource "banyan_api_key" "connector_key" {
  name              = var.connector_name
  description       = var.connector_name
  scope             = "satellite"
}

resource "banyan_connector" "connector_spec" {
  name              = var.connector_name
  satellite_api_key_id = banyan_api_key.connector_key.id
}


resource "aws_security_group" "connector_sg" {
  name        = "${var.name_prefix}-connector_sg"
  description = "Banyan connector runs in the private network, no internet-facing ports needed"
  vpc_id      = var.vpc_id

  tags = local.tags

  ingress {
    from_port         = 2222
    to_port           = 2222
    protocol          = "tcp"
    cidr_blocks       = var.management_cidrs
    description       = "Management"
  }  

  egress {
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]    
    description       = "Banyan Global Edge network"

  }
}

resource "aws_instance" "connector_vm" {

  ami             = var.ami_id != "" ? var.ami_id : data.aws_ami.default_ami.id
  instance_type   = var.instance_type
  key_name        = var.ssh_key_name

  tags = local.tags

  vpc_security_group_ids = [aws_security_group.connector_sg.id]
  subnet_id = var.subnet_id

  monitoring      = true
  ebs_optimized   = true

  ephemeral_block_device {
    device_name  = "/dev/sdc"
    virtual_name = "ephemeral0"
  }

  metadata_options {
    http_endpoint               = var.http_endpoint_imds_v2
    http_tokens                 = var.http_tokens_imds_v2
    http_put_response_hop_limit = var.http_hop_limit_imds_v2
  }

  user_data = join("", concat([
    "#!/bin/bash -ex\n",
    # use the latest, or set the specific version
    "VER=$(curl -sI https://www.banyanops.com/netting/connector/latest | awk '/Location:/ {print $2}' | grep -Po '(?<=connector-)\\S+(?=.tar.gz)')\n",
    var.package_version != null ? "VER=${var.package_version}\n": "",
    # create folder for the Tarball
    "mkdir -p /opt/banyan-packages\n",
    "cd /opt/banyan-packages\n",
    # download and unzip the files
    "wget https://www.banyanops.com/netting/connector-$VER.tar.gz\n",
    "tar zxf connector-$VER.tar.gz\n",
    "cd connector-$VER\n",
    # create the config file
    "echo 'command_center_url: ${var.banyan_host}' > connector-config.yaml\n",
    "echo 'api_key_secret: ${banyan_api_key.connector_key.secret}' >> connector-config.yaml\n",
    "echo 'connector_name: ${var.connector_name}' >> connector-config.yaml\n",
    "./setup-connector.sh\n",
    "echo 'Port 2222' >> /etc/ssh/sshd_config && /bin/systemctl restart sshd.service\n",    
    ], var.custom_user_data))
}

