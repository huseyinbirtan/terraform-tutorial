terraform {
  required_version = ">= 1.1"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {
  # Authentication via environment variables or Azure CLI
}

data "azuread_user" "cloud-architect" {
  object_id = var.main_users_object_id
}

resource "azuread_group" "project-admins" {
  display_name = "ug-project-admins"
  security_enabled = true
}

resource "azuread_group_member" "example" {
  group_object_id  = azuread_group.project-admins.object_id
  member_object_id = data.azuread_user.cloud-architect.object_id
}