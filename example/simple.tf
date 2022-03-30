provider "aws" {
  region = "us-east-1"
}

variable "api_key_secret" {
  type = string
}

module "aws_connector" {
  source                 = "banyansecurity/banyan-connector/aws"
  vpc_id                 = "vpc-0e73afd7c24062f0a"
  subnet_id              = "subnet-00e393f22c3f09e16"
  ssh_key_name           = "my-ssh-key"
  connector_name         = "my-conn"
  api_key_secret         = var.api_key_secret
}