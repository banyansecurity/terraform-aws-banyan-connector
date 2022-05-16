# Banyan AWS Connector Module

Creates an outbound Connector for use with [Banyan Security][banyan-security].

This module creates an EC2 instance for the Banyan Connector. The EC2 instance lives in a private subnet with no ingress from the internet.

## Usage

```hcl
locals {
  region = "us-east-1"
}

provider "aws" {
  region = local.region
}

module "aws_connector" {
  source                 = "banyansecurity/banyan-connector/aws"
  region                 = local.region  
  vpc_id                 = "vpc-0e73afd7c24062f0a"
  subnet_id              = "subnet-00e393f22c3f09e16"
  ssh_key_name           = "my-ssh-key"
  connector_name         = "my-banyan-connector"
  banyan_host            = "https://team.console.banyanops.com"
  banyan_api_key         = "abc123..."
}
```


## Notes

The connector is deployed in a private subnet, so the default value for `management_cidr` uses SSH open to the world on port 2222. You can use the CIDR of your VPC, or a bastion host, instead.

It's probably also a good idea to leave the `banyan_api_key` out of your code and pass it as a variable instead, so you don't accidentally commit your Banyan API token to your version control system:

```hcl
variable "banyan_api_key" {
  type = string
}

module "aws_connector" {
  source                 = "banyansecurity/banyan-connector/aws"
  banyan_api_key         = var.banyan_api_key
  ...
}
```

```bash
export TF_VAR_banyan_api_key="abc123..."
terraform plan
```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_banyan_api_key"></a> [api\_key\_secret](#input\_api\_key\_secret) | API key generated from the Banyan Command Center console | `string` | n/a | yes |
| <a name="input_banyan_host"></a> [command\_center\_url](#input\_command\_center\_url) | URL of the Banyan Command Center | `string` | `"https://team.console.banyanops.com"` | no |
| <a name="input_connector_name"></a> [connector\_name](#input\_connector\_name) | Name to use when registering this Connector with the Command Center console | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type to use when creating Connector instance | `string` | `"t3.small"` | no |
| <a name="input_management_cidrs"></a> [management\_cidrs](#input\_management\_cidrs) | CIDR blocks to allow SSH connections from | `list(string)` | `[ "0.0.0.0/0" ]` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | String to be added in front of all AWS object names | `string` | `"banyan"` | no |
| <a name="input_package_version"></a> [package\_version](#input\_package\_version) | Override to use a specific version of connector (e.g. `1.3.0`) | `string` | `null` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of an SSH key stored in AWS to allow management access | `string` | `""` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\subnet\_id) | ID of the subnet where the Connector instance should be created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Add tags to each resource | `map(any)` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which to create the Connector | `string` | n/a | yes |


## Outputs

| Name | Description |
|------|-------------|
| connector\_name | Name of the connector (example: `my-conn`) |
| sg | The ID of the security group attached to the connector instance, which can be added as an inbound rule on other backend groups (example: `sg-1234abcd`) |


## Authors

Module created and managed by [Banyan](https://github.com/banyansecurity).


## License

Licensed under Apache 2. See [LICENSE](LICENSE) for details.

[banyan-security]: https://banyansecurity.io
