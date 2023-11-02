# Combining this name_prefix with resource type in names later on enforces good naming practices for the Azure resources.

locals {
  name_prefix = "cfp${var.environment}${var.service_name}"
}

resource "azuread_application" "container_registry_contributor" {
  display_name = "${local.name_prefix}service"
}

resource "azuread_service_principal" "cr_contributor_service_principal" {
  client_id = azuread_application.container_registry_contributor.client_id
  tags      = ["container registry", "docker", "github"]
}

resource "azuread_application_password" "cr_contributor_service_principal_password" {
  application_id = azuread_application.container_registry_contributor.id
  end_date       = "2099-02-01T01:02:03Z"
}

resource "azurerm_container_registry" "acr" {
  name                = "${local.name_prefix}acr"
  resource_group_name = "${local.name_prefix}rg"
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "container_registry_contributor_role_assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.cr_contributor_service_principal.object_id
}

/* resource "azurerm_role_assignment" "cfpartners_app_service_principal_acr_role_assignment" {
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "Reader"
  principal_id         = var.cfpartners_app_service_principal_id
}

resource "azurerm_role_assignment" "cfpartners_app_service_principal_acr_acrpull_role_assignment" {
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = var.cfpartners_app_service_principal_id
} */

resource "azurerm_role_assignment" "cfpartners_service_principal_acr_acrpull_role_assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = var.cfpartners_service_principal_id
}

resource "github_actions_secret" "registry_login_server" {
  repository      = var.github_repo_name
  secret_name     = "REGISTRY_LOGIN_SERVER"
  plaintext_value = azurerm_container_registry.acr.login_server
}

resource "github_actions_secret" "registry_username" {
  repository      = var.github_repo_name
  secret_name     = "REGISTRY_USERNAME"
  plaintext_value = azuread_service_principal.cr_contributor_service_principal.id
}

resource "github_actions_secret" "registry_password" {
  repository      = var.github_repo_name
  secret_name     = "REGISTRY_PASSWORD"
  plaintext_value = azuread_application_password.cr_contributor_service_principal_password.value
}