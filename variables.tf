// Common Banyan Variables followed by cloud specific variables
variable "name" {
  type        = string
  description = "Name to use when registering this Connector with the Command Center console"
}

variable "banyan_host" {
  type        = string
  description = "URL of the Banyan Command Center"
  default     = "https://net.banyanops.com/"
}

variable "connector_version" {
  type        = string
  description = "Override to use a specific version of connector (e.g. `1.3.0`)"
  default     = ""
}

variable "cluster" {
  type        = string
  description = "Name of an existing Shield cluster to register this Connector with. This value is set automatically if omitted from the configuration"
  default     = null
}

variable "tunnel_private_domains" {
  type        = list(string)
  description = "Any internal domains that can only be resolved on your internal network’s private DNS"
  default     = null
}

variable "tunnel_cidrs" {
  type        = list(string)
  description = "Backend CIDR Ranges that correspond to the IP addresses in your private network(s)"
  default     = null
}

// AWS specific variables
variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which to create the connector"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the connector instance should be created"
}

variable "asg_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the autoscaling group. Required when asg_enabled == true"
  default     = []
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

variable "member_security_groups" {
  type        = list(string)
  description = "Additional security groups which the access tier should be a member of"
  default     = []
}

variable "asg_enabled" {
  type        = bool
  description = "Enable autoscaling group for the connector, enables self-healing"
  default     = false
}
