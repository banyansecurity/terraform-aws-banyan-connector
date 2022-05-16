variable "region" {
  type        = string
  description = "Region in AWS in which to deploy the connector"
}

variable "profile" {
  type        = string
  description = "AWS profile with your credentials"
  default     = "default"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to create the connector"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the connector instance should be created"
}

variable "ssh_key_name" {
  type        = string
  description = "Name of an SSH key stored in AWS to allow management access"
  default     = ""
}

variable "management_cidrs" {
  type        = list(string)
  description = "CIDR blocks to allow SSH connections from"
  default     = ["0.0.0.0/0"]
}

variable "package_version" {
  type        = string
  description = "Override to use a specific version of connector (e.g. `1.3.0`)"
  default     = ""
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type to use when creating Connector instance"
  default     = "t3.small"
}

variable "tags" {
  type        = map(any)
  description = "Add tags to each resource"
  default     = null
}

variable "name_prefix" {
  type        = string
  description = "String to be added in front of all AWS object names"
  default     = "banyan"
}

variable "banyan_host" {
  type        = string
  description = "URL of the Banyan Command Center"
  default     = "https://team.console.banyanops.com/"
}

variable "banyan_api_key" {
  type        = string
  description = "API Key or Refresh Token generated from the Banyan Command Center console"
}

variable "connector_name" {
  type        = string
  description = "Name to use when registering this Connector with the Command Center console"
}
