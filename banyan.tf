terraform {
  required_providers {
    banyan = {
      source  = "banyansecurity/banyan"
      version = ">=0.9.2"
    }   
  }
}

resource "banyan_connector" "connector" {
  name              = var.name
  cluster           = var.cluster
  api_key_id        = banyan_api_key.connector.id
  cidrs             = var.tunnel_cidrs
  domains           = var.tunnel_private_domains
}

resource "banyan_api_key" "connector" {
  name              = var.name
  description       = "API key for ${var.name} connector"
  scope             = "satellite"
}