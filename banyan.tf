resource "banyan_api_key" "connector" {
  name              = var.connector_name
  description       = var.connector_name
  scope             = "satellite"
}

resource "banyan_connector" "example" {
  name              = var.connector_name
  satellite_api_key_id = banyan_api_key.connector.id
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [aws_instance.conn]

  destroy_duration = "30s"
}

