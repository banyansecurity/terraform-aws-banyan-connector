output "name" {
  value       = var.name
  description = "Name to use when registering this Connector with the console"
}

output "api_key_id" {
  value = banyan_api_key.accesstier.id
  description = "ID of the API key associated with the Connector"
}

output "security_group_id" {
  value = aws_security_group.connector_sg.id
  description = "The ID of the security group, which can be added as an inbound rule on other backend groups (example: `sg-1234abcd`)"
}
