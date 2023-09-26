/*
https://learn.microsoft.com/en-us/azure/developer/terraform/configure-azure-virtual-desktop

How components are organized: https://learn.microsoft.com/en-us/azure/architecture/example-scenario/wvd/windows-virtual-desktop#relationships-between-key-logical-components

An workspace has one or more app groups, which have one or more apps
One AppGroup can belong to only one workspace
All apps and desktop when published appears under this workspace
Permissions are assigned to the Application Group (azurerm_role_assignment, "Desktop Virtualization User" role)

> azurerm_virtual_desktop_application
Creates an app to be added published. It will be added to app group in order to allow users to access them

> azurerm_virtual_desktop_application_group
You control the resources published to users through application groups
An application group can be one of two types: RemoteApp or Desktop
To publish resources to users, you must assign them to application groups

> azurerm_virtual_desktop_host_pool
> azurerm_virtual_desktop_host_pool_registration_info (creates the registration key)

https://learn.microsoft.com/en-us/azure/developer/terraform/create-avd-session-host

A host pool is a collection of Azure virtual machines that register to Azure Virtual Desktop as session hosts when you run the Azure Virtual Desktop agent. All session host 
virtual machines in a host pool should be sourced from the same image for a consistent user experience

https://learn.microsoft.com/en-us/azure/virtual-desktop/safe-url-list?tabs=azure


> azurerm_virtual_desktop_scaling_plan (depends on host_pool)
It is used to power-on or off session hosts (vms)

> azurerm_virtual_desktop_workspace
> azurerm_virtual_desktop_workspace_application_group_association
A workspace is a logical grouping of application groups in Azure Virtual Desktop. Each Azure Virtual Desktop application group must be associated with a workspace for users to 
see the desktops and applications published to them

TAGs to vms: {"cm-resource-parent":"/subscriptions/0783ffe8-281d-407a-8b7f-c61da7adb25a/resourcegroups/avd-example-rg/providers/Microsoft.DesktopVirtualization/hostpools/avd-pool1-vdpool"}
*/

locals {
  tags = merge(var.tags, { ManagedByTerraform = "True" })
}

############################################################################################################
# Defines the pool type (pooled or personal), how sessions will be handled and agent updates
############################################################################################################

resource "azurerm_virtual_desktop_host_pool" "default" {
  name                             = "${var.host_pool.name}-vdpool"
  friendly_name                    = var.host_pool.friendly_name
  description                      = var.host_pool.description
  location                         = var.location
  resource_group_name              = var.resource_group_name
  type                             = var.host_pool.type
  load_balancer_type               = var.host_pool.load_balancer_type
  validate_environment             = var.host_pool.validate_environment
  start_vm_on_connect              = var.host_pool.start_vm_on_connect
  custom_rdp_properties            = var.host_pool.custom_rdp_properties
  personal_desktop_assignment_type = var.host_pool.personal_desktop_assignment_type
  maximum_sessions_allowed         = var.host_pool.maximum_sessions_allowed
  preferred_app_group_type         = var.host_pool.preferred_app_group_type
  tags                             = local.tags

  dynamic "scheduled_agent_updates" {
    for_each = var.host_pool.scheduled_agent_updates == null ? [] : [var.host_pool.scheduled_agent_updates]
    content {
      enabled                   = true
      timezone                  = scheduled_agent_updates.value.timezone
      use_session_host_timezone = scheduled_agent_updates.use_session_host_timezone

      schedule {
        day_of_week = scheduled_agent_updates.day_of_week
        hour_of_day = scheduled_agent_updates.hour_of_day
      }
    }
  }
}

resource "time_static" "default" {
  triggers = {
    #for key, value in var.host_pool.session_host_ids : key => value
    rotation_days = 29
  }
}

#Creates the token that will be used by VMs to register to this pool
resource "azurerm_virtual_desktop_host_pool_registration_info" "default" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.default.id
  expiration_date = timeadd(time_static.default.rfc3339, "24h")
}

############################################################################################################
# Workspace
############################################################################################################
resource "azurerm_virtual_desktop_workspace" "default" {
  name                          = "${var.workspace.name}-vdws"
  friendly_name                 = var.workspace.friendly_name
  description                   = var.workspace.description
  location                      = var.location
  resource_group_name           = var.resource_group_name
  public_network_access_enabled = var.workspace.public_network_access_enabled
  tags                          = local.tags
}


############################################################################################################
# Defines which applications will be published to users and which users will have access to them
############################################################################################################
resource "azurerm_virtual_desktop_application_group" "default" {
  for_each                     = { for key, value in var.application_groups : key => value }
  name                         = "${each.key}-vdag"
  friendly_name                = each.value.friendly_name
  default_desktop_display_name = each.value.default_desktop_display_name
  description                  = each.value.description
  location                     = var.location
  resource_group_name          = var.resource_group_name
  host_pool_id                 = azurerm_virtual_desktop_host_pool.default.id
  type                         = each.value.type
  tags                         = local.tags
}

resource "azurerm_virtual_desktop_workspace_application_group_association" "default" {
  for_each             = { for key, value in var.application_groups : key => value }
  workspace_id         = azurerm_virtual_desktop_workspace.default.id
  application_group_id = azurerm_virtual_desktop_application_group.default[each.key].id
}

/*
Assign user to the Application Group
Create a new list since in the azurerm_role_assignment we need to assign a single principal_id each time
*/
locals {
  assignments = flatten([for appgrp_key, appgrp_value in var.application_groups : [
    for principal_id in appgrp_value.assignment_ids : {
      application_group_name = appgrp_key
      principal_id           = principal_id
    }
  ]])

  applications = flatten([for appgrp_key, appgrp_value in var.application_groups : [
    for app_key, app_value in appgrp_value.applications : {
      name                         = app_key
      application_group_name       = appgrp_key
      friendly_name                = app_value.friendly_name
      description                  = app_value.description
      path                         = app_value.path
      command_line_argument_policy = app_value.command_line_argument_policy
      command_line_arguments       = app_value.command_line_arguments
      show_in_portal               = app_value.show_in_portal
      icon_path                    = app_value.icon_path
      icon_index                   = app_value.icon_index
    }
  ] if appgrp_value.applications != null])
}

resource "azurerm_role_assignment" "default" {
  for_each             = { for key, value in local.assignments : "${value.application_group_name}-${value.principal_id}" => value }
  scope                = azurerm_virtual_desktop_application_group.default[each.value.application_group_name].id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = each.value.principal_id
}

resource "azurerm_virtual_desktop_application" "default" {
  for_each                     = { for key, value in local.applications : "${value.application_group_name}-${value.name}" => value }
  name                         = each.value.name
  application_group_id         = azurerm_virtual_desktop_application_group.default[each.value.application_group_name].id
  friendly_name                = each.value.friendly_name
  description                  = each.value.description
  path                         = each.value.path
  command_line_argument_policy = each.value.command_line_argument_policy
  command_line_arguments       = each.value.command_line_arguments
  show_in_portal               = each.value.show_in_portal
  icon_path                    = each.value.icon_path
  icon_index                   = each.value.icon_index
}

############################################################################################################
# Register VMs to the pool
############################################################################################################
resource "azurerm_virtual_machine_extension" "AVDDsc" {
  for_each                   = toset(var.host_pool.session_host_ids)
  name                       = "${split("/", each.key)[8]}-AVDDsc"
  virtual_machine_id         = each.key
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = <<-SETTINGS
    {
      "modulesUrl": "${var.artifact_location}",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName": "${azurerm_virtual_desktop_host_pool.default.name}"
      }
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
  {
    "properties": {
      "registrationInfoToken": "${azurerm_virtual_desktop_host_pool_registration_info.default.token}"
    }
  }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

# ############################################################################################################
# # If Azure AD joined VMs, grant RBAC permissions
# ############################################################################################################

# resource "azurerm_role_assignment" "default" {
#   scope                = azurerm_resource_group.default.id
#   role_definition_name = "Virtual Machine Administrator Login"
#   principal_id         = data.azurerm_client_config.default.object_id
# }
