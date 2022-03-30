locals {
  tags = merge(var.tags, {
    Provider = "BanyanOps"
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

resource "aws_security_group" "sg" {
  name        = "${var.name_prefix}-connector-sg"
  description = "Connector engress traffic (no ingress needed)"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = "0.0.0.0/0"
    description = "Banyan Global Edge network"
  }

  tags = merge(local.tags, var.security_group_tags)
}

resource "aws_instance" "conn" {
  ami             = var.ami_id != "" ? var.ami_id : data.aws_ami.default_ami.id
  instance_type   = var.instance_type
  key_name        = var.ssh_key_name
  security_groups = [aws_security_group.sg.id]
  ebs_optimized   = true

  iam_instance_profile = var.iam_instance_profile

  ephemeral_block_device {
    device_name  = "/dev/sdc"
    virtual_name = "ephemeral0"
  }

  metadata_options {
    http_endpoint               = var.http_endpoint_imds_v2
    http_tokens                 = var.http_tokens_imds_v2
    http_put_response_hop_limit = var.http_hop_limit_imds_v2
  }


  lifecycle {
    create_before_destroy = true
  }

  user_data = join("", concat([
    "#!/bin/bash -ex\n",
    # increase file handle limits
    "echo '* soft nofile 100000' >> /etc/security/limits.d/banyan.conf\n",
    "echo '* hard nofile 100000' >> /etc/security/limits.d/banyan.conf\n",
    "echo 'fs.file-max = 100000' >> /etc/sysctl.d/90-banyan.conf\n",
    "sysctl -w fs.file-max=100000\n",
    # increase conntrack hashtable limits
    "echo 'options nf_conntrack hashsize=65536' >> /etc/modprobe.d/banyan.conf\n",
    "modprobe nf_conntrack\n",
    "echo '65536' > /proc/sys/net/netfilter/nf_conntrack_buckets\n",
    "echo '262144' > /proc/sys/net/netfilter/nf_conntrack_max\n",
    # install dogstatsd (if requested)
    var.datadog_api_key != null ? "curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh | DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=${var.datadog_api_key} DD_SITE=datadoghq.com bash -v\n" : "",
    # install prerequisites and Banyan netagent
    "yum update -y\n",
    "yum install -y jq tar gzip curl sed python3\n",
    "pip3 install --upgrade pip\n",
    "/usr/local/bin/pip3 install pybanyan\n", # previous line changes /bin/pip3 to /usr/local/bin which is not in the path
    "rpm --import https://www.banyanops.com/onramp/repo/RPM-GPG-KEY-banyan\n",
    "yum-config-manager --add-repo https://www.banyanops.com/onramp/repo\n",
    "while [ -f /var/run/yum.pid ]; do sleep 1; done\n",
    "yum install -y ${var.package_name} \n",
    # configure and start netagent
    "cd /opt/banyan-packages\n",
    "BANYAN_ACCESS_TIER=true ",
    "BANYAN_REDIRECT_TO_HTTPS=${var.redirect_http_to_https} ",
    "BANYAN_SITE_NAME=${var.site_name} ",
    "BANYAN_SITE_ADDRESS=${aws_alb.nlb.dns_name} ",
    "BANYAN_SITE_DOMAIN_NAMES=", join(",", var.site_domain_names), " ",
    "BANYAN_SITE_AUTOSCALE=true ",
    "BANYAN_API=${var.api_server} ",
    "BANYAN_HOST_TAGS=", join(",", [for k, v in var.host_tags : format("%s=%s", k, v)]), " ",
    "BANYAN_ACCESS_EVENT_CREDITS_LIMITING=${var.rate_limiting.enabled} ",
    "BANYAN_ACCESS_EVENT_CREDITS_MAX=${var.rate_limiting.max_credits} ",
    "BANYAN_ACCESS_EVENT_CREDITS_INTERVAL=${var.rate_limiting.interval} ",
    "BANYAN_ACCESS_EVENT_CREDITS_PER_INTERVAL=${var.rate_limiting.credits_per_interval} ",
    "BANYAN_ACCESS_EVENT_KEY_LIMITING=${var.rate_limiting.enable_by_key} ",
    "BANYAN_ACCESS_EVENT_KEY_EXPIRATION=${var.rate_limiting.key_lifetime} ",
    "BANYAN_GROUPS_BY_USERINFO=${var.groups_by_userinfo} ",
    var.datadog_api_key != null ? "BANYAN_STATSD=true BANYAN_STATSD_ADDRESS=127.0.0.1:8125 " : "",
    "./install ${var.refresh_token} ${var.cluster_name} \n",
    "echo 'Port 2222' >> /etc/ssh/sshd_config && /bin/systemctl restart sshd.service\n",
  ], var.custom_user_data))
}