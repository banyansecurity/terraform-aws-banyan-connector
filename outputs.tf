output "sg" {
  value = aws_security_group.connector_sg.id
}

output "connector_name" {
  value = var.connector_name
}