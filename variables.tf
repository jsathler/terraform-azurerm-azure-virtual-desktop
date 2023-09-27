variable "location" {
  description = "The region where the VM will be created. This parameter is required"
  type        = string
  nullable    = false
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created. This parameter is required"
  type        = string
  nullable    = false
}

variable "tags" {
  description = "Tags to be applied to resources."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "artifact_location" {
  description = "The Azure artifact containing the 'setup files' for AVD. This variable will be out-of-date over time, use the last version when possible"
  type        = string
  default     = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02439.203.zip"
  nullable    = false
}

variable "workspace" {
  description = <<DESCRIPTION
  Workspace parameters. This parameter is required'
  - name:                          (required) The name of the Virtual Desktop Workspace
  - friendly_name:                 (optional) A friendly name for the Virtual Desktop Workspace
  - description:                   (optional) A description for the Virtual Desktop Workspace
  - public_network_access_enabled: (optional) Whether public network access is allowed for this Virtual Desktop Workspace. Defaults to true
  DESCRIPTION

  type = object({
    name                          = string
    friendly_name                 = optional(string, null)
    description                   = optional(string, null)
    public_network_access_enabled = optional(bool, true)
  })

  nullable = false
}

variable "host_pool" {
  description = <<DESCRIPTION
  Host Pool parameters. This parameter is required'
  - name:                             (required) The name of the Virtual Desktop Host Pool
  - session_host_ids:                 (required) A Map of VM names and IDs that will be part of this Host Pool. The required agents will be installed on VMs. An internet access is required according to https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites?tabs=portal#network
  - friendly_name:                    (optional) A friendly name for the Virtual Desktop Host Pool. Defaults to null
  - description:                      (optional) A description for the Virtual Desktop Host Pool. Defaults to null
  - type:                             (optional) The type of the Virtual Desktop Host Pool. Valid options are Personal or Pooled. Defaults to Pooled
  - load_balancer_type:               (optional) How AVD load balancing distributes new user sessions across all available session hosts in the host pool. Valid values are BreadthFirst, DepthFirst and Persistent. Defaults to BreadthFirst
  - validate_environment:             (optional) Allows you to test service changes before they are deployed to production. Defaults to false
  - start_vm_on_connect:              (optional) Enables or disables the Start VM on Connection Feature. Defaults to false
  - custom_rdp_properties             (optional) A valid custom RDP properties string for the Virtual Desktop Host Pool. Defaults to null
  - personal_desktop_assignment_type: (optional) How AVD will select an available host and assign it to an user. Valid values are Automatic and Direct. Defaults to null
  - maximum_sessions_allowed:         (optional) A valid integer value from 0 to 999999 for the maximum number of users that have concurrent sessions on a session host. Defaults to null
  - preferred_app_group_type:         (optional) Option to specify the preferred Application Group type for the Virtual Desktop Host Pool. Valid options are None, Desktop or RailApplications. Default is Desktop
  - scheduled_agent_updates:          (optional) A block as defined bellow
    - timezone:                       (optional) Specifies the time zone in which the agent update schedule will apply. Default is UTC
    - use_session_host_timezone:      (optional) Specifies whether scheduled agent updates should be applied based on the timezone of the affected session host. If configured then this setting overrides timezone. Default is false
    - day_of_week:                    (optional) The day of the week on which agent updates should be performed. Possible values are Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday
    - hour_of_day:                    (optional) The hour of day the update window should start. The update is a 2 hour period following the hour provided. The value should be provided as a number between 0 and 23. Defaults to 22
  - aadjoin:                          (optional) Define if VMs are Azure AD Joined. Defaults to false
  - aad_scope_id                      (optional) If aadjoin is set to true, you should provide the Resource Group or Subscription ID to grant 'Virtual Machine Administrator Login' and/or 'Virtual Machine User Login'. It is recommended to use the Resource Group ID where VMs were provisioned
  DESCRIPTION
  type = object({
    name                             = string
    friendly_name                    = optional(string, null)
    description                      = optional(string, null)
    type                             = optional(string, "Pooled")
    load_balancer_type               = optional(string, "BreadthFirst")
    validate_environment             = optional(bool, false)
    start_vm_on_connect              = optional(bool, false)
    custom_rdp_properties            = optional(string, null)
    personal_desktop_assignment_type = optional(string, null)
    maximum_sessions_allowed         = optional(string, null)
    preferred_app_group_type         = optional(string, "Desktop")
    scheduled_agent_updates = optional(object({
      timezone                  = optional(string, "UTC")
      use_session_host_timezone = optional(bool, false)
      day_of_week               = optional(string, "Saturday")
      hour_of_day               = optional(number, 22)
    }), null)
    session_host_ids = map(string)
    aadjoin          = optional(bool, false)
    aad_scope_id     = optional(string, null)
  })

  nullable = false

  validation {
    condition     = can(index(["Pooled", "Personal"], var.host_pool.type) >= 0)
    error_message = "Valid values are Pooled and Personal."
  }
  validation {
    condition     = can(index(["BreadthFirst", "DepthFirst", "Persistent"], var.host_pool.load_balancer_type) >= 0)
    error_message = "Valid values are BreadthFirst, DepthFirst, Persistent."
  }
  validation {
    condition     = var.host_pool.type == "Personal" ? var.host_pool.load_balancer_type == "Persistent" : true
    error_message = "If type is Personal, load_balancer_type should be Persistent"
  }
  validation {
    condition     = var.host_pool.personal_desktop_assignment_type != null ? can(index(["Automatic", "Direct"], var.host_pool.personal_desktop_assignment_type) >= 0) : true
    error_message = "Valid values are Automatic and Direct."
  }
  validation {
    condition     = var.host_pool.type == "Personal" ? var.host_pool.personal_desktop_assignment_type != null : true
    error_message = "If type is Personal, personal_desktop_assignment_type should be set"
  }
  validation {
    condition     = var.host_pool.aadjoin ? var.host_pool.validate_environment : true
    error_message = "If aadjoin is true, validate_environment should be true"
  }
  validation {
    condition     = var.host_pool.aadjoin ? var.host_pool.aad_scope_id != null : true
    error_message = "If aadjoin is true, aad_scope_id should be set"
  }
  validation {
    condition     = var.host_pool.aadjoin ? strcontains(var.host_pool.custom_rdp_properties == null ? "" : var.host_pool.custom_rdp_properties, "targetisaadjoined:i:1") : true
    error_message = "If aadjoin is true, custom_rdp_properties should contain 'targetisaadjoined:i:1'"
  }
}

variable "application_groups" {
  description = <<DESCRIPTION
  Application Groups parameters. This parameter is required'
  - friendly_name:                  (optional) Option to set a friendly name for the Virtual Desktop Application Group
  - default_desktop_display_name:   (optional) Option to set the display name for the default sessionDesktop desktop when type is set to Desktop
  - description:                    (optional) Option to set a description for the Virtual Desktop Application Group
  - type:                           (optional) Type of Virtual Desktop Application Group. Valid options are RemoteApp or Desktop application groups. Defaults to RemoteApp
  - assignment_ids:                 (required) A list of object IDs to grant 'Desktop Virtualization User' role to allow users access this Application Group
  - admin_ids:                      (optional) A list of object IDs to grant 'Virtual Machine Administrator Login' role to allow administrators manage Azure AD joined VMs
  - applications:                   (required) A block as defined bellow. Optional if type is Desktop
    - friendly_name:                (optional) Option to set a friendly name for the Virtual Desktop Application
    - description:                  (optional) Option to set a description for the Virtual Desktop Application
    - path:                         (required) The file path location of the app on the Virtual Desktop OS
    - command_line_argument_policy: (optional) Specifies whether this published application can be launched with command line arguments provided by the client, command line arguments specified at publish time, or no command line arguments at all. Possible values include: DoNotAllow, Allow, Require. Defaults to DoNotAllow
    - command_line_arguments:       (optional) Command Line Arguments for Virtual Desktop Application
    - show_in_portal:               (optional) Specifies whether to show the RemoteApp program in the RD Web Access server. Defaults to true
    - icon_path:                    (optional) Specifies the path for an icon which will be used for this Virtual Desktop Application
    - icon_index:                   (optional) The index of the icon you wish to use. Defaults to 0
  DESCRIPTION

  type = map(object({
    friendly_name                = optional(string, null)
    default_desktop_display_name = optional(string, null)
    description                  = optional(string, null)
    type                         = optional(string, "RemoteApp")
    assignment_ids               = list(string)
    admin_ids                    = optional(list(string), null)
    applications = optional(map(object({
      friendly_name                = optional(string, null)
      description                  = optional(string, null)
      path                         = string
      command_line_argument_policy = optional(string, "DoNotAllow")
      command_line_arguments       = optional(string, null)
      show_in_portal               = optional(bool, true)
      icon_path                    = optional(string, null)
      icon_index                   = optional(number, 0)
    })), null)
  }))

  nullable = false

  validation {
    condition     = alltrue([for app in var.application_groups : can(index(["RemoteApp", "Desktop"], app.type) >= 0)])
    error_message = "Valid values are RemoteApp and Desktop."
  }

  validation {
    condition     = alltrue([for app in var.application_groups : app.applications != null if app.type == "RemoteApp"])
    error_message = "If type is RemoteApp, applications shoud be set."
  }
}
