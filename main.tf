locals {
  tags = merge(var.tags, {
    Provider = "Banyan"
    Name     = "${var.name}-banyan-connector"
  })
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

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
  name        = "${var.name}-connector-${random_string.random.result}"
  description = "Banyan connector runs in the private network, no internet-facing ports needed"
  vpc_id      = var.vpc_id

  tags = local.tags

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.management_cidrs
    description = "Management"
  }

  ingress {
    from_port = 9443
    to_port   = 9443
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Banyan Global Edge network"

  }
}

resource "random_string" "random" {
  length           = 3
  special          = true
  override_special = "-"
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

resource "aws_launch_configuration" "connector_config" {
  count           = var.asg_enabled ? 1 : 0
  name_prefix     = "connector-${var.name}-${random_string.random.result}-"
  image_id        = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  key_name        = var.ssh_key_name
  user_data       = local.init_script
  security_groups = concat([aws_security_group.connector_sg.id], var.member_security_groups)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "connector_asg" {
  count                = var.asg_enabled ? 1 : 0
  launch_configuration = aws_launch_configuration.connector_config[0].id
  vpc_zone_identifier  = var.asg_subnet_ids
  target_group_arns    = [aws_lb_target_group.connector_tg[0].arn]
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  name                 = local.tags.Name

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  force_delete              = true

  lifecycle {
    create_before_destroy = true
  }
}

## LB is necessary for health checks to occur on target group
## Does not actually pass traffic
resource "aws_lb" "connector_lb" {
  count = var.asg_enabled ? 1 : 0

  security_groups    = concat([aws_security_group.connector_sg.id], var.member_security_groups)
  name               = local.tags.Name
  internal           = true
  load_balancer_type = "network"
  subnets            = local.one_subnet_per_az

  tags = local.tags
}

resource "aws_lb_target_group" "connector_tg" {
  count    = var.asg_enabled ? 1 : 0
  name     = local.tags.Name
  port     = 9443
  protocol = "TCP"
  vpc_id   = var.vpc_id

  health_check {
    protocol            = "TCP"
    port                = "traffic-port"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }
}

resource "aws_lb_listener" "connector_listener" {
  count             = var.asg_enabled ? 1 : 0
  load_balancer_arn = aws_lb.connector_lb[0].arn
  port              = 9443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.connector_tg[0].arn
  }
}

resource "aws_instance" "connector_vm" {
  count         = var.asg_enabled ? 0 : 1
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.ssh_key_name

  tags = local.tags

  vpc_security_group_ids = concat([aws_security_group.connector_sg.id], var.member_security_groups)
  subnet_id              = var.subnet_id

  monitoring    = true
  ebs_optimized = true

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

