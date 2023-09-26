variable "location" {
  description = "The region where the VM will be created. This parameter is required"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created. This parameter is required"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources."
  type        = map(string)
  default     = {}
}

variable "artifact_location" {
  type     = string
  default  = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02439.203.zip"
  nullable = false
}

variable "workspace" {
  type = object({
    name                          = string
    friendly_name                 = optional(string, null)
    description                   = optional(string, null)
    public_network_access_enabled = optional(bool, true)
  })
}

variable "host_pool" {
  type = object({
    name                             = string
    friendly_name                    = optional(string, null)
    description                      = optional(string, null)
    type                             = optional(string, "Pooled")
    load_balancer_type               = optional(string, "BreadthFirst") #Persistent  if type = Personal
    validate_environment             = optional(bool, false)
    start_vm_on_connect              = optional(bool, false)
    custom_rdp_properties            = optional(string, null)
    personal_desktop_assignment_type = optional(string, null)      #Automatic  or Direct if type = personal
    maximum_sessions_allowed         = optional(string, null)      #if type = pooled
    preferred_app_group_type         = optional(string, "Desktop") #Desktop  or RailApplications
    scheduled_agent_updates = optional(object({
      timezone                  = optional(string, "UTC")
      use_session_host_timezone = optional(bool, false) #overrides timezone
      day_of_week               = optional(string, "Saturday")
      hour_of_day               = optional(number, 22)
    }), null)
    session_host_ids = list(string)
  })
}

variable "application_groups" {
  type = map(object({
    friendly_name                = optional(string, null)
    default_desktop_display_name = optional(string, null)
    description                  = optional(string, null)
    type                         = optional(string, "RemoteApp")
    assignment_ids               = list(string)
    applications = optional(map(object({
      friendly_name                = optional(string, null)
      description                  = optional(string, null)
      path                         = string
      command_line_argument_policy = optional(string, "DoNotAllow")
      command_line_arguments       = optional(string, null)
      show_in_portal               = optional(bool, false)
      icon_path                    = optional(string, null)
      icon_index                   = optional(number, 0)
    })), null)
  }))
}
