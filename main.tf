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

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
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

# wait for a connector to be unhealthy before the API objects can be deleted
resource "time_sleep" "connector_health_check" {
  depends_on = [banyan_connector.connector_spec]

  destroy_duration = "5m"
}

locals {
  init_script = <<INIT_SCRIPT
#!/bin/bash
# use the latest, or set the specific version
LATEST_VER=$(curl -sI https://www.banyanops.com/netting/connector/latest | awk '/Location:/ {print $2}' | grep -Po '(?<=connector-)\S+(?=.tar.gz)')
INPUT_VER="${var.package_version}"
VER="$LATEST_VER" && [[ ! -z "$INPUT_VAR" ]] && VER="$INPUT_VER"
# create folder for the Tarball
mkdir -p /opt/banyan-packages
cd /opt/banyan-packages
# download and unzip the files
wget https://www.banyanops.com/netting/connector-$VER.tar.gz
tar zxf connector-$VER.tar.gz
cd connector-$VER
# create the config file
echo 'command_center_url: ${var.banyan_host}' > connector-config.yaml
echo 'api_key_secret: ${banyan_api_key.connector_key.secret}' >> connector-config.yaml
echo 'connector_name: ${var.connector_name}' >> connector-config.yaml
./setup-connector.sh
echo 'Port 2222' >> /etc/ssh/sshd_config && /bin/systemctl restart sshd.service
INIT_SCRIPT
}

resource "aws_instance" "connector_vm" {
  depends_on = [time_sleep.connector_health_check]

  ami             = data.aws_ami.ubuntu.id
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
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  user_data = local.init_script
}

