output "workspace_id" {
  value = azurerm_virtual_desktop_workspace.default.id
}

output "workspace_name" {
  value = azurerm_virtual_desktop_workspace.default.name
}

output "host_pool_id" {
  value = azurerm_virtual_desktop_host_pool.default.id
}

output "host_pool_name" {
  value = azurerm_virtual_desktop_host_pool.default.name
}

output "application_groups" {
  value = { for key, value in azurerm_virtual_desktop_application_group.default : value.name => value.id }
}

# output "applications" {
#   value = { for key, value in azurerm_virtual_desktop_application.default : value.application_group_id => value.name }
# }
