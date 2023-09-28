output "workspace_id" {
  description = "Workspace ID"
  value       = azurerm_virtual_desktop_workspace.default.id
}

output "workspace_name" {
  description = "Workspace name"
  value       = azurerm_virtual_desktop_workspace.default.name
}

output "host_pool_id" {
  description = "Host Pool ID"
  value       = azurerm_virtual_desktop_host_pool.default.id
}

output "host_pool_name" {
  description = "Host Pool name"
  value       = azurerm_virtual_desktop_host_pool.default.name
}

output "application_groups" {
  description = "Application group names and ids"
  value       = { for key, value in azurerm_virtual_desktop_application_group.default : value.name => value.id }
}

output "applications" {
  description = "Application names and ids"
  value       = { for key, value in azurerm_virtual_desktop_application.default : value.name => value.id }
}
