terraform {
  required_providers {
    banyan = {
      #source  = "banyansecurity/banyan"
      #version = ">=0.9.1"
      version = "~> 1.0.0"
      source  = "banyansecurity.io/banyansecurity/banyan"      
    }   
  }
}

resource "banyan_connector" "connector" {
  name              = var.name
  cluster           = var.cluster
  api_key_id        = banyan_api_key.connector.id
}

resource "banyan_api_key" "connector" {
  name              = var.name
  description       = "API key for ${var.name} connector"
  scope             = "satellite"
}