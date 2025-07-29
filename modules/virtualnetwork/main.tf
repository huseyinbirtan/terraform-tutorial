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
}

resource "azurerm_virtual_network" "vn" {
    name = "vnet-${local.resource_suffixes}"
    address_space = [ "10.0.0.0/16" ]
    location = local.location
    resource_group_name = local.resource_group_name
}

resource "azurerm_subnet" "sbs" {
  for_each             = var.subnets
  name                 = "sb-${each.key}-${local.resource_suffixes}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.${each.value.ip_3rd_octet}.0/24"]
  private_endpoint_network_policies               = each.value.private ? "Enabled" : "Disabled"
  private_link_service_network_policies_enabled   = each.value.private
}

resource "azurerm_private_dns_zone" "pdz" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = local.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdz-vnl" {
  name                  = "pdz-vnet-link-t"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.pdz.name
  virtual_network_id    = azurerm_virtual_network.vn.id
}