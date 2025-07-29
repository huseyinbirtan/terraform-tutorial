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

data "azuread_group" "project-admins" {
  display_name = "ug-project-admins"
}

resource "azurerm_mssql_server" "dbs" {
  name                         = "dbs-${local.resource_suffixes}"
  resource_group_name          = local.resource_group_name
  location                     = local.location
  version                      = "12.0"
  public_network_access_enabled = false
  azuread_administrator {
    azuread_authentication_only = true
    login_username = data.azuread_group.project-admins.display_name
    object_id      = data.azuread_group.project-admins.object_id
  }
}  

resource "azurerm_private_endpoint" "dbs-private_endpoint" {
  name                = "pe-dbs-${local.resource_suffixes}"
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-dbs-${local.resource_suffixes}"
    private_connection_resource_id = azurerm_mssql_server.dbs.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

resource "azurerm_mssql_database" "sqldb" {
  name         = "sqldb-${local.resource_suffixes}"
  server_id    = azurerm_mssql_server.dbs.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "S0"
  enclave_type = "VBS"

  lifecycle {
    prevent_destroy = false
  }
}