terraform {
  required_version = ">= 1.1"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" { 
  features {}
}

locals {
  resource_suffixes     = var.resource_suffixes
  resource_group_name   = "rg-${local.resource_suffixes}"
  location              = var.location
  agw_name              = "agw-${local.resource_suffixes}"
}

resource "azurerm_public_ip" "pip" {
    name = "pip-${local.resource_suffixes}"
    resource_group_name = local.resource_group_name
    location = local.location
    allocation_method = "Static"
    sku = "Standard"
}

resource "azurerm_application_gateway" "application_gateway" {
  name                = local.agw_name
  resource_group_name = local.resource_group_name
  location            = local.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "${local.agw_name}-ip-conf"
    subnet_id = var.subnet_id
  }

  frontend_port {
    name = "${local.agw_name}-fe-port"
    port = 80
  }

  frontend_ip_configuration {
    name                    = "${local.agw_name}-fe-ip-conf"
    public_ip_address_id    = azurerm_public_ip.pip.id
  }

  backend_address_pool {
    name            = "${local.agw_name}-be-add-pool"
    fqdns = toset([
        for hostname in var.appservice_hostnames : hostname
    ])
  }

  backend_http_settings {
    name                  = "${local.agw_name}-be-http-settings"
    cookie_based_affinity = "Disabled"
    pick_host_name_from_backend_address = true
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "${local.agw_name}-http-listener"
    frontend_ip_configuration_name = "${local.agw_name}-fe-ip-conf"
    frontend_port_name             = "${local.agw_name}-fe-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "${local.agw_name}-req-routing-rule"
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = "${local.agw_name}-http-listener"
    backend_address_pool_name  = "${local.agw_name}-be-add-pool"
    backend_http_settings_name = "${local.agw_name}-be-http-settings"
  }
}