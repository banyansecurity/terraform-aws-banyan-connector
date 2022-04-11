output "sg" {
  value = aws_security_group.sg.id
}

output "connector_name" {
  value = var.connector_name
}