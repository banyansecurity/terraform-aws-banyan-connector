output "name" {
  value = var.name
}

output "sg" {
  value = aws_security_group.connector_sg.id
}
