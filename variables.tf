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

variable "scaling_plan" {
  description = <<DESCRIPTION
  - name:                                   (required) The name which should be used for this Virtual Desktop Scaling Plan 
  - enabled:                                (optional) Specifies if the scaling plan is enabled or disabled for the HostPool
  - friendly_name:                          (optional) Friendly name of the Scaling Plan
  - description:                            (optional) A description of the Scaling Plan
  - timezone:                               (optional) Specifies the Time Zone which should be used by the Scaling Plan for time based events. Defaults to UTC
  - exclusion_tag:                          (optional) he name of the tag associated with the VMs you want to exclude from autoscaling
  - schedule:                               (required) A block as defined bellow
    - days_of_week:                         (optional) A list of Days of the Week on which this schedule will be used. Defaults to '["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]'
    - off_peak_start_time:                  (optional) The time at which Off-Peak scaling will begin. This is also the end-time for the Ramp-Down period. Defaults to 20:00
    - off_peak_load_balancing_algorithm:    (optional) The load Balancing Algorithm to use during Off-Peak Hours. Possible values are DepthFirst and BreadthFirst. Defaults to DepthFirst
    - peak_start_time:                      (optional) The time at which Peak scaling will begin. This is also the end-time for the Ramp-Up period. Defaults to 09:00
    - peak_load_balancing_algorithm:        (optional) The load Balancing Algorithm to use during Peak Hours. Possible values are DepthFirst and BreadthFirst. Defaults to DepthFirst
    - ramp_up_capacity_threshold_percent:   (optional) This is the value of percentage of used host pool capacity that will be considered to evaluate whether to turn on/off virtual machines during the ramp-up and peak hours. Defaults to 60
    - ramp_up_load_balancing_algorithm:     (optional) The load Balancing Algorithm to use during the Ramp-Up period. Possible values are DepthFirst and BreadthFirst.Defaults to BreadthFirst
    - ramp_up_start_time:                   (optional) The time at which Ramp-Up scaling will begin. This is also the end-time for the Ramp-Up period. Defaults to 08:00
    - ramp_up_minimum_hosts_percent:        (optional) Specifies the minimum percentage of session host virtual machines to start during ramp-up for peak hours. Defauls to 20
    - ramp_down_capacity_threshold_percent: (optional) This is the value in percentage of used host pool capacity that will be considered to evaluate whether to turn on/off virtual machines during the ramp-down and off-peak hours. Defaults to 90
    - ramp_down_force_logoff_users:         (optional) Whether users will be forced to log-off session hosts once the ramp_down_wait_time_minutes value has been exceeded during the Ramp-Down period. Defaults to true
    - ramp_down_load_balancing_algorithm:   (optional) The load Balancing Algorithm to use during the Ramp-Down period. Possible values are DepthFirst and BreadthFirst. Defaults to DepthFirst
    - ramp_down_minimum_hosts_percent:      (optional) The minimum percentage of session host virtual machines that you would like to get to for ramp-down and off-peak hours. Defaults to 10
    - ramp_down_notification_message:       (optional) The notification message to send to users during Ramp-Down period when they are required to log-off. Defaults to "You will be logged off in 30 min. Make sure to save your work."
    - ramp_down_start_time:                 (optional) The time at which Ramp-Down scaling will begin. This is also the end-time for the Ramp-Up period. Defaults to 18:00
    - ramp_down_stop_hosts_when:            (optional) Controls Session Host shutdown behaviour during Ramp-Down period. Session Hosts can either be shutdown when all sessions on the Session Host have ended, or when there are no Active sessions left on the Session Host. Possible values are ZeroSessions and ZeroActiveSessions. Default to ZeroSessions
    - ramp_down_wait_time_minutes:          (optional) The number of minutes during Ramp-Down period that autoscale will wait after setting the session host VMs to drain mode, notifying any currently signed in users to save their work before forcing the users to logoff. Defaults to 30

  DESCRIPTION
  type = object({
    name          = string
    enabled       = optional(bool, true)
    friendly_name = optional(string, null)
    description   = optional(string, null)
    timezone      = optional(string, "UTC")
    exclusion_tag = optional(string, null)
    schedule = map(object({
      days_of_week                         = optional(list(string), ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"])
      off_peak_start_time                  = optional(string, "20:00")
      off_peak_load_balancing_algorithm    = optional(string, "DepthFirst")
      peak_start_time                      = optional(string, "09:00")
      peak_load_balancing_algorithm        = optional(string, "DepthFirst")
      ramp_up_capacity_threshold_percent   = optional(number, 60)
      ramp_up_load_balancing_algorithm     = optional(string, "BreadthFirst")
      ramp_up_start_time                   = optional(string, "08:00")
      ramp_up_minimum_hosts_percent        = optional(number, 20)
      ramp_down_capacity_threshold_percent = optional(number, 90)
      ramp_down_force_logoff_users         = optional(bool, true)
      ramp_down_load_balancing_algorithm   = optional(string, "DepthFirst")
      ramp_down_minimum_hosts_percent      = optional(number, 10)
      ramp_down_notification_message       = optional(string, "You will be logged off in 30 min. Make sure to save your work.")
      ramp_down_start_time                 = optional(string, "18:00")
      ramp_down_stop_hosts_when            = optional(string, "ZeroSessions")
      ramp_down_wait_time_minutes          = optional(number, 30)
    }))
  })

  default = null

  validation {
    condition = var.scaling_plan == null ? true : alltrue([for schedule in var.scaling_plan.schedule :
      can([for weekday in schedule.days_of_week : index(["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Satuday"], weekday) >= 0])
    ])
    error_message = "Valid values for days_of_week are Sunday, Monday, Tuesday, Wednesday, Thursday, Friday and Satuday."
  }

  validation {
    condition = var.scaling_plan == null ? true : alltrue([for schedule in var.scaling_plan.schedule :
      can(index(["BreadthFirst", "DepthFirst"], schedule.off_peak_load_balancing_algorithm) >= 0) &&
      can(index(["BreadthFirst", "DepthFirst"], schedule.peak_load_balancing_algorithm) >= 0) &&
      can(index(["BreadthFirst", "DepthFirst"], schedule.ramp_up_load_balancing_algorithm) >= 0) &&
      can(index(["BreadthFirst", "DepthFirst"], schedule.ramp_down_load_balancing_algorithm) >= 0)
    ])
    error_message = "Valid values for off_peak_load_balancing_algorithm, peak_load_balancing_algorithm, ramp_up_load_balancing_algorithm and ramp_down_load_balancing_algorithm are BreadthFirst and DepthFirst."
  }

  validation {
    condition = var.scaling_plan == null ? true : alltrue([for schedule in var.scaling_plan.schedule :
      can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", schedule.off_peak_start_time)) &&
      can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", schedule.peak_start_time)) &&
      can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", schedule.ramp_up_start_time)) &&
      can(regex("^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$", schedule.ramp_down_start_time))
    ])
    error_message = "off_peak_start_time, peak_start_time, ramp_up_start_time and ramp_down_start_time should be in format HH:MM (00:00 - 23:59)"
  }

  validation {
    condition = var.scaling_plan == null ? true : alltrue([for schedule in var.scaling_plan.schedule :
      (schedule.ramp_up_capacity_threshold_percent >= 0 && schedule.ramp_up_capacity_threshold_percent <= 100) &&
      (schedule.ramp_up_minimum_hosts_percent >= 0 && schedule.ramp_up_minimum_hosts_percent <= 100) &&
      (schedule.ramp_down_capacity_threshold_percent >= 0 && schedule.ramp_down_capacity_threshold_percent <= 100) &&
      (schedule.ramp_down_minimum_hosts_percent >= 0 && schedule.ramp_down_minimum_hosts_percent <= 100)
    ])
    error_message = "Valid values for ramp_up_capacity_threshold_percent, ramp_up_minimum_hosts_percent, ramp_down_capacity_threshold_percent and ramp_down_minimum_hosts_percent are between 1 and 100"
  }

  validation {
    condition     = var.scaling_plan == null ? true : alltrue([for schedule in var.scaling_plan.schedule : can(index(["ZeroActiveSessions", "ZeroSessions"], schedule.ramp_down_stop_hosts_when) >= 0)])
    error_message = "Valid values for ramp_down_stop_hosts_when are ZeroActiveSessions and ZeroSessions."
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

output "validate_application_groups" {
  value = null

  precondition {
    condition     = var.host_pool.type == "Personal" ? length(var.application_groups) <= 1 : true
    error_message = "If host pool type is Personal, You can have only one application group."
  }
}

output "validate_scaling_plan" {
  value = null

  precondition {
    condition     = var.host_pool.type == "Personal" ? var.scaling_plan == null : true
    error_message = "Currently Terraform does not support creating scaling plan of type Personal."
  }
}
