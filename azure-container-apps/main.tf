# Combining this name_prefix with resource type in names later on enforces good naming practices for the Azure resources.

locals {
  name_prefix = "cfp${var.environment}${var.service_name}"
}

data "azurerm_client_config" "current" {}

resource "azurerm_application_insights" "app_insights" {
  name                = "${local.name_prefix}appi"
  location            = var.location
  resource_group_name = "${local.name_prefix}rg"
  application_type    = "other"
}

resource "azurerm_log_analytics_workspace" "cfpartners_law" {
  name                = "${local.name_prefix}law"
  location            = var.location
  resource_group_name = "${local.name_prefix}rg"
}

resource "azurerm_container_app_environment" "cfpartners_cae" {
  name                       = "${local.name_prefix}cae"
  location                   = var.location
  resource_group_name        = "${local.name_prefix}rg"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cfpartners_law.id
}

resource "azurerm_user_assigned_identity" "containerapp" {
  location            = var.location
  name                = "containerappmi"
  resource_group_name = "${local.name_prefix}rg"
}

resource "azurerm_role_assignment" "containerapp" {
  scope                = var.cfpartners_azurerm_container_registry_id
  role_definition_name = "acrpull"
  principal_id         = azurerm_user_assigned_identity.containerapp.principal_id
  depends_on = [
    azurerm_user_assigned_identity.containerapp
  ]
}

resource "azurerm_container_app" "cfpartners_db" {
  name                         = "${local.name_prefix}dbca"
  container_app_environment_id = azurerm_container_app_environment.cfpartners_cae.id
  resource_group_name          = "${local.name_prefix}rg"
  revision_mode                = "Single"

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 80
    traffic_weight {
      percentage = 100
    }
  }

  registry {
    server   = var.cfpartners_azurerm_container_registry_loginserver
    identity = azurerm_user_assigned_identity.containerapp.id
  }

  template {
    container {
      name   = "cfpartners_dbcontainer"
      image  = "${var.cfpartners_azurerm_container_registry_loginserver}/cfpartners_dbcontainer:latest"
      cpu    = 0.25
      memory = "0.5Gi"

      readiness_probe {
        transport = "HTTP"
        port      = 80
      }

      liveness_probe {
        transport = "HTTP"
        port      = 80
      }

      startup_probe {
        transport = "HTTP"
        port      = 80
      }
    }
  }

}
