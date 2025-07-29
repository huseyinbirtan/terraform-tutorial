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
  app_service_instances = var.app_service_instances
}

resource "azurerm_log_analytics_workspace" "lw" {
  name                = "lw-${local.resource_suffixes}"
  location            = local.location
  resource_group_name = local.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appin" {
  name                = "appin-${local.resource_suffixes}"
  location            = local.location
  resource_group_name = local.resource_group_name
  workspace_id        = azurerm_log_analytics_workspace.lw.id
  application_type    = "web"
}

resource "azurerm_service_plan" "asp" {
  name                = "asp-${local.resource_suffixes}"
  location            = local.location
  resource_group_name = local.resource_group_name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "as-linux" {
  count               = local.app_service_instances
  name                = "as-${local.resource_suffixes}-${count.index}"
  location            = local.location
  resource_group_name = local.resource_group_name
  service_plan_id     = azurerm_service_plan.asp.id

  site_config {
    ip_restriction_default_action = "Deny"
    ip_restriction {
      name                      = "AllowSubnet"
      virtual_network_subnet_id = var.subnet_agw_id
      action                    = "Allow"
      priority                  = 100
    }
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.appin.instrumentation_key
  }

  identity {
    type = "SystemAssigned"
  }

  https_only                    = false
}

locals {
  app_service_map = {
    for idx, app in azurerm_linux_web_app.as-linux :
    "app-${idx}" => {
      id           = app.id
      name         = app.name
      principal_id = app.identity[0].principal_id
    }
  }
}

resource "azurerm_private_endpoint" "as-private_endpoint" {
  for_each            = local.app_service_map
  name                = "pe-${each.value.name}"
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = var.subnet_as_id

  private_service_connection {
    name                           = "psc-${each.value.name}"
    private_connection_resource_id = each.value.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }
}

locals {
  azurerm_private_endpoints = {
    for idx, pe in azurerm_private_endpoint.as-private_endpoint :
    pe.name => {
      ip           = pe.private_service_connection[0].private_ip_address
    }
  }
  app_service_records_map = {
    for idx, app in azurerm_linux_web_app.as-linux :
    "record-${idx}" => {
      name         = app.name
      ip           = local.azurerm_private_endpoints["pe-${app.name}"].ip
    }
  }
}

resource "azurerm_private_dns_a_record" "pdns-record" {
  for_each            = local.app_service_records_map
  name                = each.value.name
  zone_name           = "privatelink.azurewebsites.net"
  resource_group_name = local.resource_group_name
  ttl                 = 10
  records             = [each.value.ip]
}