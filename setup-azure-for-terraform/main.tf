# Combining this name_prefix with resource type in names later on enforces good naming practices for the Azure resources.

locals {
  name_prefix = "cfp${var.environment}${var.service_name}"
}

data "azurerm_client_config" "current" { }

resource "azurerm_resource_group" "cfpartners_rg" {
  name     = "${local.name_prefix}rg"
  location = var.location
}

resource "azuread_application" "cfpartners_application" {
  display_name = "${local.name_prefix}service"

  web {
    redirect_uris = [
      "https://${var.custom_domain}/api/auth/microsoft/handler/frame"
    ]
  }
}

resource "azuread_service_principal" "service_principal" {
  client_id = azuread_application.cfpartners_application.client_id
}

resource "azuread_application_password" "cfpartners_app_password" {
  application_id        = azuread_application.cfpartners_application.id
  end_date              = "2099-01-01T01:02:03Z"
}

resource "azurerm_storage_account" "tfstate_storage" {
  name                          = "${local.name_prefix}st"
  resource_group_name           = azurerm_resource_group.cfpartners_rg.name
  location                      = azurerm_resource_group.cfpartners_rg.location
  public_network_access_enabled = true
  
  account_tier                  = "Standard"
  account_replication_type      = "GRS"
}

resource "azurerm_role_assignment" "service_principal_storage_access" {
  scope                = azurerm_storage_account.tfstate_storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.service_principal.object_id
}

resource "azurerm_storage_container" "tfstate_storage_container" {
  name                  = "${local.name_prefix}tfstate"
  storage_account_name  = azurerm_storage_account.tfstate_storage.name
  container_access_type = "private"
}

resource "github_actions_secret" "github_tfstate_container_name" {
  repository       = "${var.github_repo_name}"
  secret_name      = "TFSTATE_CONTAINER_NAME"
  plaintext_value  = azurerm_storage_container.tfstate_storage_container.name
}

resource "github_actions_secret" "github_tfstate_storage_account_name" {
  repository       = "${var.github_repo_name}"
  secret_name      = "TFSTATE_STORAGE_ACCOUNT"
  plaintext_value  = azurerm_storage_account.tfstate_storage.name
}

resource "github_actions_secret" "github_azure_subscription_id" {
  repository       = "${var.github_repo_name}"
  secret_name      = "AZURE_SUBSCRIPTION_ID"
  plaintext_value  = data.azurerm_client_config.current.subscription_id
}

resource "github_actions_secret" "github_azure_tenant_id" {
  repository       = "${var.github_repo_name}"
  secret_name      = "AZURE_TENANT_ID"
  plaintext_value  = data.azurerm_client_config.current.tenant_id
}

resource "github_actions_secret" "github_azure_client_id" {
  repository       = "${var.github_repo_name}"
  secret_name      = "AZURE_CLIENT_ID"
  plaintext_value  = azuread_service_principal.service_principal.client_id
}

resource "github_actions_secret" "github_azure_client_secret" {
  repository       = "${var.github_repo_name}"
  secret_name      = "AZURE_CLIENT_SECRET"
  plaintext_value  = azuread_application_password.cfpartners_app_password.value
}

resource "github_actions_secret" "azure_credentials" {
  repository       = "${var.github_repo_name}"
  secret_name      = "AZURE_CREDENTIALS"
  plaintext_value  = jsonencode({
    "clientId" = azuread_service_principal.service_principal.client_id
    "clientSecret" = azuread_application_password.cfpartners_app_password.value
    "subscriptionId" = data.azurerm_client_config.current.subscription_id
    "tenantId" = data.azurerm_client_config.current.tenant_id
  })
}