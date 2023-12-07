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

resource "time_rotating" "default" {
  rotation_days = 1
}

#Creates the token that will be used by VMs to register to this pool
resource "azurerm_virtual_desktop_host_pool_registration_info" "default" {
  hostpool_id     = azurerm_virtual_desktop_host_pool.default.id
  expiration_date = timeadd(time_rotating.default.rfc3339, "24h")
}

data "azuread_service_principal" "scaling_plan" {
  count          = var.scaling_plan != null && var.host_pool.type == "Pooled" ? 1 : 0
  application_id = "9cdead84-a844-4324-93f2-b2e6bb768d07"
}

resource "azurerm_role_assignment" "scaling_plan" {
  count                = var.scaling_plan != null && var.host_pool.type == "Pooled" ? 1 : 0
  scope                = azurerm_virtual_desktop_host_pool.default.id
  role_definition_name = "Desktop Virtualization Power On Off Contributor"
  principal_id         = data.azuread_service_principal.scaling_plan[0].id
}

resource "azurerm_virtual_desktop_scaling_plan" "default" {
  count               = var.scaling_plan != null && var.host_pool.type == "Pooled" ? 1 : 0
  name                = "${var.scaling_plan.name}-vdscaling"
  friendly_name       = var.scaling_plan.friendly_name
  description         = var.scaling_plan.description
  location            = var.location
  resource_group_name = var.resource_group_name
  time_zone           = var.scaling_plan.timezone
  tags                = local.tags

  dynamic "schedule" {
    for_each = { for key, value in var.scaling_plan.schedule : key => value }
    content {
      name                                 = schedule.key
      days_of_week                         = schedule.value.days_of_week
      off_peak_start_time                  = schedule.value.off_peak_start_time
      off_peak_load_balancing_algorithm    = schedule.value.off_peak_load_balancing_algorithm
      peak_start_time                      = schedule.value.peak_start_time
      peak_load_balancing_algorithm        = schedule.value.peak_load_balancing_algorithm
      ramp_up_capacity_threshold_percent   = schedule.value.ramp_up_capacity_threshold_percent
      ramp_up_load_balancing_algorithm     = schedule.value.ramp_up_load_balancing_algorithm
      ramp_up_start_time                   = schedule.value.ramp_up_start_time
      ramp_up_minimum_hosts_percent        = schedule.value.ramp_up_minimum_hosts_percent
      ramp_down_capacity_threshold_percent = schedule.value.ramp_down_capacity_threshold_percent
      ramp_down_force_logoff_users         = schedule.value.ramp_down_force_logoff_users
      ramp_down_load_balancing_algorithm   = schedule.value.ramp_down_load_balancing_algorithm
      ramp_down_minimum_hosts_percent      = schedule.value.ramp_down_minimum_hosts_percent
      ramp_down_notification_message       = schedule.value.ramp_down_notification_message
      ramp_down_start_time                 = schedule.value.ramp_down_start_time
      ramp_down_stop_hosts_when            = schedule.value.ramp_down_stop_hosts_when
      ramp_down_wait_time_minutes          = schedule.value.ramp_down_wait_time_minutes
    }
  }

  host_pool {
    hostpool_id          = azurerm_virtual_desktop_host_pool.default.id
    scaling_plan_enabled = var.scaling_plan.enabled
  }
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

resource "azurerm_virtual_desktop_application" "default" {
  #If this dependency is not set, applications will be published with no icons
  depends_on                   = [azurerm_virtual_machine_extension.AVDDsc]
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

/*
Assign user to the Application Group
Create a new list since in the azurerm_role_assignment we can assign only one principal_id at time
*/
locals {
  assignments = flatten([for appgrp_key, appgrp_value in var.application_groups : [
    for principal_id in appgrp_value.assignment_ids : {
      application_group_name = appgrp_key
      principal_id           = principal_id
    }
  ]])

  admin_assignments = flatten([for appgrp_key, appgrp_value in var.application_groups : [
    for principal_id in appgrp_value.admin_ids : {
      application_group_name = appgrp_key
      principal_id           = principal_id
    }
  ] if appgrp_value.admin_ids != null])

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

resource "azurerm_role_assignment" "app_group" {
  for_each             = { for key, value in local.assignments : "${value.application_group_name}-${value.principal_id}" => value }
  scope                = azurerm_virtual_desktop_application_group.default[each.value.application_group_name].id
  role_definition_name = "Desktop Virtualization User"
  principal_id         = each.value.principal_id
}

resource "azurerm_role_assignment" "rg_user" {
  for_each             = var.host_pool.aadjoin ? toset(distinct([for assignment in local.assignments : assignment.principal_id])) : []
  scope                = var.host_pool.aad_scope_id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "rg_admin" {
  for_each             = var.host_pool.aadjoin ? toset(distinct([for assignment in local.admin_assignments : assignment.principal_id])) : []
  scope                = var.host_pool.aad_scope_id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = each.value
}

############################################################################################################
# Register VMs to the pool
############################################################################################################
resource "azurerm_virtual_machine_extension" "AVDDsc" {
  for_each                   = { for key, value in var.host_pool.session_host_ids : key => value }
  name                       = "${each.key}-AVDDsc"
  virtual_machine_id         = each.value
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true
  tags                       = local.tags

  settings = <<-SETTINGS
    {
      "modulesUrl": "${var.artifact_location}",
      "configurationFunction": "Configuration.ps1\\AddSessionHost",
      "properties": {
        "HostPoolName": "${azurerm_virtual_desktop_host_pool.default.name}",
        %{if(var.host_pool.aadjoin) != null} "aadJoin": true, %{endif}
        "UseAgentDownloadEndpoint": true
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
