# Banyan AWS Connector Module

Creates an outbound Connector for use with [Banyan Security][banyan-security].

This module creates an EC2 instance for the Banyan Connector. The EC2 instance lives in a private subnet with no ingress from the internet.

## Usage

```hcl
provider "aws" {
  region = "us-east-1"
}

module "aws_connector" {
  source                 = "banyansecurity/banyan-connector/aws"
  vpc_id                 = "vpc-0e73afd7c24062f0a"
  subnet_id              = "subnet-00e393f22c3f09e16"
  ssh_key_name           = "my-ssh-key"
  connector_name         = "my-banyan-connector"
  api_key_secret         = "abc123..."
}
```


## Notes

The connector is deployed in a private subnet, so the default value for `management_cidr` uses SSH open to the world on port 2222. You can use the CIDR of your VPC, or a bastion host, instead.

It's probably also a good idea to leave the `api_key_secret` out of your code and pass it as a variable instead, so you don't accidentally commit your Banyan API token to your version control system:

```hcl
variable "api_key_secret" {
  type = string
}

module "aws_connector" {
  source                 = "banyansecurity/banyan-connector/aws"
  api_key_secret         = var.api_key_secret
  ...
}
```

```bash
export TF_VAR_api_key_secret="abc123..."
terraform plan
```


## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | ID of a custom AMI to use when creating a Connector instance (leave blank to use default) | `string` | `""` | no |
| <a name="input_api_key_secret"></a> [api\_key\_secret](#input\_api\_key\_secret) | API key generated from the Banyan Command Center console | `string` | n/a | yes |
| <a name="input_command_center_url"></a> [command\_center\_url](#input\_command\_center\_url) | URL of the Banyan Command Center | `string` | `"https://team.console.banyanops.com"` | no |
| <a name="input_connector_name"></a> [connector\_name](#input\_connector\_name) | Name to use when registering this Connector with the Command Center console | `string` | n/a | yes |
| <a name="input_custom_user_data"></a> [custom\_user\_data](#input\_custom\_user\_data) | Custom commands to append to the launch configuration initialization script. | `list(string)` | `[]` | no |
| <a name="input_default_ami_name"></a> [default\_ami\_name](#input\_default\_ami\_name) | If no AMI ID is supplied, use the most recent AMI from this project | `string` | `"amzn2-ami-hvm-2.0.*-x86_64-ebs"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type to use when creating Connector instance | `string` | `"t3.small"` | no |
| <a name="input_management_cidrs"></a> [management\_cidrs](#input\_management\_cidrs) | CIDR blocks to allow SSH connections from | `list(string)` | `[ "0.0.0.0/0" ]` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | String to be added in front of all AWS object names | `string` | `"banyan"` | no |
| <a name="input_package_version"></a> [package\_version](#input\_package\_version) | Override to use a specific version of connector (e.g. `1.3.0`) | `string` | `null` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of an SSH key stored in AWS to allow management access | `string` | `""` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\subnet\_id) | ID of the subnet where the Connector instance should be created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Add tags to each resource | `map(any)` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which to create the Connector | `string` | n/a | yes |
| <a name="input_http_endpoint_imds_v2"></a> [http\_endpoint\_imds\_v2](#input\_http\_endpoint\_imds\_v2) | Value for http_endpoint to enable imds v2 for ec2 instance | `string` | `"enabled"` | no |
| <a name="input_http_tokens_imds_v2"></a> [http\_tokens\_imds\_v2](#input\_http\_tokens\_imds\_v2) | Value for http_tokens to enable imds v2 for ec2 instance | `string` | `"required"` | no |
| <a name="input_http_hop_limit_imds_v2"></a> [http\_hop\_limit\_imds\_v2](#input\_http\_hop\_limit\_imds\_v2) | Value for http_put_response_hop_limit to enable imds v2 for ec2 instance | `number` | `1` | no |


## Outputs

None


## Authors

Module created and managed by [Tarun Desikan](https://github.com/tdesikan).


## License

Licensed under Apache 2. See [LICENSE](LICENSE) for details.

[banyan-security]: https://banyansecurity.io
