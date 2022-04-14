variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to create the Connector"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the Connector instance should be created"
}

variable "package_version" {
  type        = string
  description = "Override to use a specific version of connector (e.g. `1.3.0`)"
  default     = null
}

variable "management_cidrs" {
  type        = list(string)
  description = "CIDR blocks to allow SSH connections from"
  default     = ["0.0.0.0/0"]
}

variable "ssh_key_id" {
  type        = string
  description = "Name of an SSH key stored in AWS to allow management access"
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type to use when creating Connector instance"
  default     = "t3.small"
}

variable "ami_id" {
  type        = string
  description = "ID of a custom AMI to use when creating a Connector instance (leave blank to use default)"
  default     = ""
}

variable "default_ami_name" {
  type        = string
  description = "If no AMI ID is supplied, use the most recent AMI from this project"
  default     = "amzn2-ami-hvm-2.0.*-x86_64-ebs"
}

variable "custom_user_data" {
  type        = list(string)
  description = "Custom commands to append to the launch configuration initialization script."
  default     = []
}

variable "tags" {
  type        = map(any)
  description = "Add tags to each resource"
  default     = null
}

variable "security_group_tags" {
  type        = map
  description = "Additional tags to the security_group"
  default     = null
}

variable "name_prefix" {
  type        = string
  description = "String to be added in front of all AWS object names"
  default     = "banyan"
}

variable "http_endpoint_imds_v2" {
  type        = string
  description = "value for http_endpoint to enable imds v2 for ec2 instance"
  default     = "enabled"
}

variable "http_tokens_imds_v2" {
  type        = string
  description = "value for http_tokens to enable imds v2 for ec2 instance"
  default     = "required"
}

variable "http_hop_limit_imds_v2" {
  type        = number
  description = "value for http_put_response_hop_limit to enable imds v2 for ec2 instance"
  default     = 1
}

variable "banyan_host" {
  type        = string
  description = "URL of the Banyan Command Center"
  default     = "https://team.console.banyanops.com/"
}

variable "banyan_api_key" {
  type        = string
  description = "API key generated from the Banyan Command Center console"
}

variable "connector_name" {
  type        = string
  description = "Name to use when registering this Connector with the Command Center console"
}

variable "region" {
  type = string
}