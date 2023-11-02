output "azurerm_container_app_url" {
  value = azurerm_container_app.cfpartners_db.latest_revision_fqdn
}