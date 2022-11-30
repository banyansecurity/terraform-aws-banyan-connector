# Banyan AWS Connector Module

This module creates an EC2 instance for the Banyan Connector. The EC2 instance lives in a private subnet with no ingress from the internet.

## Usage

```hcl
provider "banyan" {
  api_key = var.api_key
}

provider "aws" {
  region = "us-east-1"
}

module "aws_connector" {
  source                 = "banyansecurity/banyan-connector/aws"
  
  name                   = "my-banyan-connector"
  vpc_id                 = "vpc-0e73afd7c24062f0a"
  subnet_id              = "subnet-00e393f22c3f09e16"
  member_security_groups = [aws_security_group.allow_conn.id]
}
```


## Notes

The connector is deployed in a private subnet, so the default value for `management_cidr` uses SSH open to the world on port 22. You can use the CIDR of your VPC, or a bastion host, instead.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_banyan"></a> [banyan](#requirement\_banyan) | >=0.9.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_banyan"></a> [banyan](#provider\_banyan) | >=0.9.2 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_security_group.sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_instance.connector_vm](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [banyan_api_key.accesstier](https://registry.terraform.io/providers/banyansecurity/banyan/latest/docs/resources/api_key) | resource |
| [banyan_connector.connector](https://registry.terraform.io/providers/banyansecurity/banyan/latest/docs/resources/connector) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Name to use when registering this Connector with the Command Center console | `string` | n/a | yes |
| <a name="input_banyan_host"></a> [command\_center\_url](#input\_command\_center\_url) | URL of the Banyan Command Center | `string` | `"https://net.banyanops.com"` | no |
| <a name="input_connector_version"></a> [package\_version](#input\_connector\_version) | Override to use a specific version of connector (e.g. `1.3.0`) | `string` | `null` | no |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Name of an existing Shield cluster to register this Access Tier with. This value is set automatically if omitted from the configuration | `string` | `null` | no |
| <a name="input_tunnel_private_domains"></a> [tunnel\_private\_domains](#input\_tunnel\_private\_domains) | Any internal domains that can only be resolved on your internal network’s private DNS | `list(string)` | `null` | no |
| <a name="input_tunnel_cidrs"></a> [tunnel\_cidrs](#input\_tunnel\_cidrs) | Backend CIDR Ranges that correspond to the IP addresses in your private network(s) | `list(string)` | `null` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | EC2 instance type to use when creating Connector instance | `string` | `"t3.small"` | no |
| <a name="input_management_cidrs"></a> [management\_cidrs](#input\_management\_cidrs) | CIDR blocks to allow SSH connections from | `list(string)` | `[ "0.0.0.0/0" ]` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | String to be added in front of all AWS object names | `string` | `"banyan"` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of an SSH key stored in AWS to allow management access | `string` | `""` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\subnet\_id) | ID of the subnet where the Connector instance should be created | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Add tags to each resource | `map(any)` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which to create the Connector | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_api_key_id"></a> [api\_key\_id](#output\_api\_key\_id) | ID of the API key associated with the Connector |
| <a name="output_name"></a> [name](#output\_name) | Name to use when registering this Connector with the console |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | The ID of the security group, which can be added as an inbound rule on other backend groups (example: `sg-1234abcd`) |
<!-- END_TF_DOCS -->

