# Combining this name_prefix with resource type in names later on enforces good naming practices for the Azure resources.

locals {
  name_prefix = "cfpartners${var.environment}${var.service_name}"
  app_service_ip_address = distinct(split(",", azurerm_app_service.cfpartners_app.outbound_ip_addresses))
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
  application_id        = azuread_application.cfpartners_application.application_id
  end_date              = "2099-01-01T01:02:03Z"
}

resource "azurerm_storage_account" "tfstate_storage" {
  name                          = "${local.name_prefix}storage"
  resource_group_name           = azurerm_resource_group.cfpartners_rg.name
  location                      = azurerm_resource_group.cfpartners_rg.location
  public_network_access_enabled = false
  
  account_tier                  = "Standard"
  account_replication_type      = "GRS"
}

resource "azurerm_storage_container" "tfstate_storage_container" {
  name                  = "${local.name_prefix}tfstate"
  storage_account_name  = azurerm_storage_account.tfstate_storage.name
  container_access_type = "private"
}

/* Start of resources pertaining to app service */

resource "azurerm_role_assignment" "service_principal_storage_access" {
  scope                = azurerm_storage_account.tfstate_storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azuread_service_principal.service_principal.object_id
}

resource "azurerm_application_insights" "app_insights" {
  name                = "${local.name_prefix}appi"
  location            = azurerm_resource_group.cfpartners_rg.location
  resource_group_name = azurerm_resource_group.cfpartners_rg.name
  application_type    = "other"
}

resource "azurerm_app_service_plan" "cfpartners_app_plan" {
  name                = "${local.name_prefix}plan"
  location            = azurerm_resource_group.cfpartners_rg.location
  resource_group_name = azurerm_resource_group.cfpartners_rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "cfpartners_app" {
  name                = "${local.name_prefix}app"
  location            = azurerm_resource_group.cfpartners_rg.location
  resource_group_name = azurerm_resource_group.cfpartners_rg.name
  app_service_plan_id = azurerm_app_service_plan.cfpartners_app_plan.id

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "AZURE_CLIENT_ID" = azuread_application.cfpartners_application.application_id
    "AZURE_CLIENT_SECRET" = azuread_application_password.ocs_app_password.value
    "AZURE_TENANT_ID" = data.azurerm_client_config.current.tenant_id
    "POSTGRES_HOST" = azurerm_postgresql_server.cfpartners_postgresql.fqdn
    "POSTGRES_PORT" = 5432
    "POSTGRES_USER" = "${var.db_admin_username}@${azurerm_postgresql_server.cfpartners_postgresql.fqdn}"
    "POSTGRES_PASSWORD" = var.db_admin_password
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.app_insights.instrumentation_key
    "DOCKER_REGISTRY_SERVER_USERNAME" = azuread_application.cfpartners_application.application_id
    "DOCKER_REGISTRY_SERVER_PASSWORD" = azuread_application_password.cfpartners_app_password.value
    "CUSTOM_DOMAIN" = var.custom_domain
    "GITHUB_cfpartners_APPID" = var.github_cfpartners_appid
    "GITHUB_cfpartners_WEBHOOKURL" = var.github_cfpartners_webhookUrl
    "GITHUB_cfpartners_CLIENTID" = var.github_cfpartners_clientId
    "GITHUB_cfpartners_CLIENTSECRET" = var.github_cfpartners_clientSecret
    "GITHUB_cfpartners_WEBHOOKSECRET" = var.github_cfpartners_webhookSecret
    "GITHUB_cfpartners_PRIVATEKEY" = var.github_cfpartners_privateKey
    "TFSTATE_CONTAINER_NAME" = azurerm_storage_container.tfstate_storage_container.name
    "TFSTATE_STORAGE_ACCOUNT" = azurerm_storage_account.tfstate_storage.name
  }
}

resource "azurerm_role_assignment" "app_service_contributor_role_assignment" {
  scope                = azurerm_app_service.cfpartners_app.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.service_principal.object_id
}

resource "github_actions_secret" "app_name" {
  repository       = "${var.github_repo_name}"
  secret_name      = "APP_NAME"
  plaintext_value  = azurerm_app_service.cfpartners_app.name
}

/* End of resources pertaining to app service */

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
  plaintext_value  = azuread_service_principal.service_principal.application_id
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
    "clientId" = azuread_service_principal.service_principal.application_id
    "clientSecret" = azuread_application_password.backstage_app_password.value
    "subscriptionId" = data.azurerm_client_config.current.subscription_id
    "tenantId" = data.azurerm_client_config.current.tenant_id
  })
}