terraform {
  required_providers {
    banyan = {
      source  = "github.com/banyansecurity/banyan"
      version = "0.6.1"
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
}

provider "banyan" {
  api_token = var.banyan_api_key
  host      = var.banyan_host
}

locals {
  tags = {
    Provider = "Banyan"
    Name = "${var.name_prefix}-connector"
  }
}

data aws_ami "default_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.default_ami_name]
  }
}

variable "connector_sg" {
  default = ""
}

resource "aws_security_group" "connector_sg" {
  name        = "${var.name_prefix}-connector"
  description = "Allow all traffic from banyan connector"
  vpc_id      = var.vpc_id

  ingress {
    cidr_blocks       = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    description       = "allow all members of associated security groups access to the connector"
  }

  egress {
    cidr_blocks       = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "conn" {
  ami             = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.ssh_key_id

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
    "sudo apt update -y\n",
    "sudo apt install -y ca-certificates curl gnupg lsb-release\n",
    "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg\n",
    "sudo echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null\n",
    "sudo apt update -y\n",
    "sudo apt install -y docker-ce docker-ce-cli containerd.io \n",
    "sudo systemctl enable docker.service\n",
    "sudo systemctl enable containerd.service\n",
    "export COMMAND_CENTER_URL=\"${var.banyan_host}\"\n",
    "export API_KEY_SECRET=\"${banyan_api_key.connector.secret}\"\n",
    "export CONNECTOR_NAME=\"${var.connector_name}\"\n",
    "sudo docker run --name connector --privileged --cap-add=NET_ADMIN -e COMMAND_CENTER_URL=$COMMAND_CENTER_URL -e API_KEY_SECRET=$API_KEY_SECRET -e CONNECTOR_NAME=$CONNECTOR_NAME -d gcr.io/banyan-pub/connector:latest\n",
    "sleep 10 && sudo docker logs connector\n",
  ]))
}