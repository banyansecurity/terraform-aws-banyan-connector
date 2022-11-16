locals {
  tags = merge(var.tags, {
    Provider = "Banyan"
    Name = "${var.name}"
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

resource "aws_security_group" "connector_sg" {
  name        = "${var.name}-connector_sg"
  description = "Banyan connector runs in the private network, no internet-facing ports needed"
  vpc_id      = var.vpc_id

  tags = local.tags

  ingress {
    from_port         = 22
    to_port           = 22
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

locals {
  init_script = <<INIT_SCRIPT
#!/bin/bash
# use the latest, or set the specific version
LATEST_VER=$(curl -sI https://www.banyanops.com/netting/connector/latest | awk '/Location:/ {print $2}' | grep -Po '(?<=connector-)\S+(?=.tar.gz)')
INPUT_VER="${var.connector_version}"
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
echo 'api_key_secret: ${banyan_api_key.connector.secret}' >> connector-config.yaml
echo 'connector_name: ${var.name}' >> connector-config.yaml
./setup-connector.sh
INIT_SCRIPT
}

resource "aws_instance" "connector_vm" {
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

