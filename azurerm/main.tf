terraform {
  required_version = ">= 1.1"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" { 
  features {}
}

provider "azuread" {
  # Authentication via environment variables or Azure CLI
}

data "azurerm_client_config" "current"{

}

locals {
  project_name          = "-tf-tutorial"
  resource_suffixes     = "${var.location}${local.project_name}-${var.environment}"
  resource_group_name   = "rg-${local.resource_suffixes}"
  location              = var.location_map[var.location]
  tenant_id             = data.azurerm_client_config.current.tenant_id
  object_id             = data.azurerm_client_config.current.object_id
  app_service_instances = 2
}

data "azuread_group" "project-admins" {
  display_name = "ug-project-admins"
}

resource "azurerm_resource_group" "rg" {
    name = local.resource_group_name
    location = local.location
}

resource "azurerm_role_assignment" "project-admins-network" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = data.azuread_group.project-admins.object_id
}

module "virtualnetwork" {
  source            = "../modules/virtualnetwork"
  resource_suffixes = local.resource_suffixes
  location          = local.location
  subnets           = {
    "pri-as" : {
      ip_3rd_octet = 1
      private = true
    }
    "pri-db" : {
      ip_3rd_octet = 2
      private = true
    }
    "pub" : {
      ip_3rd_octet = 3
      private = false
    }
  }
}

module "appserviceplan" {
  source                = "../modules/appservice"
  resource_suffixes     = local.resource_suffixes
  location              = local.location
  app_service_instances = local.app_service_instances
  subnet_as_id          = module.virtualnetwork.subnets["pri-as"].id
  subnet_agw_id         = module.virtualnetwork.subnets["pub"].id
}

module "applicationgateway" {
  source                = "../modules/applicationgateway"
  resource_suffixes     = local.resource_suffixes
  location              = local.location
  appservice_hostnames  = [for appservice in module.appserviceplan.appservices : appservice.hostname]
  subnet_id             = module.virtualnetwork.subnets["pub"].id
}


module "database" {
  source                = "../modules/database"
  resource_suffixes     = local.resource_suffixes
  location              = local.location
  subnet_id             = module.virtualnetwork.subnets["pri-db"].id
}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-${local.resource_suffixes}"
  location                    = local.location
  resource_group_name         = local.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = local.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = local.tenant_id
    object_id = local.object_id

    secret_permissions = [
      "Get", "List", "Set"
    ]
  }
}

resource "azurerm_key_vault_access_policy" "kv-as-accesspolicy" {
  for_each      = module.appserviceplan.appservices
  key_vault_id  = azurerm_key_vault.kv.id

  tenant_id     = local.tenant_id
  object_id     = each.value.identity_principal_id

  secret_permissions = [
    "Get", "List"
  ]
}
