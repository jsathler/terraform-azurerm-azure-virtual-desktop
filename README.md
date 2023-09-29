<!-- BEGIN_TF_DOCS -->
# Azure Virtual Desktop Terraform module

Terraform module which creates Azure Virtual Desktop resources on Azure.

Supported Azure services:

* [Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/virtual-desktop/overview)
* [Azure Virtual Desktop Host Pools](https://learn.microsoft.com/en-us/azure/virtual-desktop/terminology#host-pools)
* [Azure Virtual Desktop Application Groups](https://learn.microsoft.com/en-us/azure/virtual-desktop/terminology#application-groups)
* [Azure Virtual Desktop Workspaces](https://learn.microsoft.com/en-us/azure/virtual-desktop/terminology#workspaces)
* [Azure Virtual Desktop Scaling Plan*](https://learn.microsoft.com/en-us/azure/virtual-desktop/autoscale-scenarios#how-a-scaling-plan-works)
* [Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview)
* [Azure AD-joined virtual machines in Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/virtual-desktop/azure-ad-joined-session-hosts)

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.6 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.70.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | n/a |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3.70.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_role_assignment.app_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.rg_admin](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.rg_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.scaling_plan](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_virtual_desktop_application.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application) | resource |
| [azurerm_virtual_desktop_application_group.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_application_group) | resource |
| [azurerm_virtual_desktop_host_pool.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool) | resource |
| [azurerm_virtual_desktop_host_pool_registration_info.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_host_pool_registration_info) | resource |
| [azurerm_virtual_desktop_scaling_plan.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_scaling_plan) | resource |
| [azurerm_virtual_desktop_workspace.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace) | resource |
| [azurerm_virtual_desktop_workspace_application_group_association.default](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_desktop_workspace_application_group_association) | resource |
| [azurerm_virtual_machine_extension.AVDDsc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_machine_extension) | resource |
| [time_static.default](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/static) | resource |
| [azuread_service_principal.scaling_plan](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/service_principal) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_groups"></a> [application\_groups](#input\_application\_groups) | Application Groups parameters. This parameter is required'<br>  - friendly\_name:                  (optional) Option to set a friendly name for the Virtual Desktop Application Group<br>  - default\_desktop\_display\_name:   (optional) Option to set the display name for the default sessionDesktop desktop when type is set to Desktop<br>  - description:                    (optional) Option to set a description for the Virtual Desktop Application Group<br>  - type:                           (optional) Type of Virtual Desktop Application Group. Valid options are RemoteApp or Desktop application groups. Defaults to RemoteApp<br>  - assignment\_ids:                 (required) A list of object IDs to grant 'Desktop Virtualization User' role to allow users access this Application Group<br>  - admin\_ids:                      (optional) A list of object IDs to grant 'Virtual Machine Administrator Login' role to allow administrators manage Azure AD joined VMs<br>  - applications:                   (required) A block as defined bellow. Optional if type is Desktop<br>    - friendly\_name:                (optional) Option to set a friendly name for the Virtual Desktop Application<br>    - description:                  (optional) Option to set a description for the Virtual Desktop Application<br>    - path:                         (required) The file path location of the app on the Virtual Desktop OS<br>    - command\_line\_argument\_policy: (optional) Specifies whether this published application can be launched with command line arguments provided by the client, command line arguments specified at publish time, or no command line arguments at all. Possible values include: DoNotAllow, Allow, Require. Defaults to DoNotAllow<br>    - command\_line\_arguments:       (optional) Command Line Arguments for Virtual Desktop Application<br>    - show\_in\_portal:               (optional) Specifies whether to show the RemoteApp program in the RD Web Access server. Defaults to true<br>    - icon\_path:                    (optional) Specifies the path for an icon which will be used for this Virtual Desktop Application<br>    - icon\_index:                   (optional) The index of the icon you wish to use. Defaults to 0 | <pre>map(object({<br>    friendly_name                = optional(string, null)<br>    default_desktop_display_name = optional(string, null)<br>    description                  = optional(string, null)<br>    type                         = optional(string, "RemoteApp")<br>    assignment_ids               = list(string)<br>    admin_ids                    = optional(list(string), null)<br>    applications = optional(map(object({<br>      friendly_name                = optional(string, null)<br>      description                  = optional(string, null)<br>      path                         = string<br>      command_line_argument_policy = optional(string, "DoNotAllow")<br>      command_line_arguments       = optional(string, null)<br>      show_in_portal               = optional(bool, true)<br>      icon_path                    = optional(string, null)<br>      icon_index                   = optional(number, 0)<br>    })), null)<br>  }))</pre> | n/a | yes |
| <a name="input_artifact_location"></a> [artifact\_location](#input\_artifact\_location) | The Azure artifact containing the 'setup files' for AVD. This variable will be out-of-date over time, use the last version when possible | `string` | `"https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02439.203.zip"` | no |
| <a name="input_host_pool"></a> [host\_pool](#input\_host\_pool) | Host Pool parameters. This parameter is required'<br>  - name:                             (required) The name of the Virtual Desktop Host Pool<br>  - session\_host\_ids:                 (required) A Map of VM names and IDs that will be part of this Host Pool. The required agents will be installed on VMs. An internet access is required according to https://learn.microsoft.com/en-us/azure/virtual-desktop/prerequisites?tabs=portal#network<br>  - friendly\_name:                    (optional) A friendly name for the Virtual Desktop Host Pool. Defaults to null<br>  - description:                      (optional) A description for the Virtual Desktop Host Pool. Defaults to null<br>  - type:                             (optional) The type of the Virtual Desktop Host Pool. Valid options are Personal or Pooled. Defaults to Pooled<br>  - load\_balancer\_type:               (optional) How AVD load balancing distributes new user sessions across all available session hosts in the host pool. Valid values are BreadthFirst, DepthFirst and Persistent. Defaults to BreadthFirst<br>  - validate\_environment:             (optional) Allows you to test service changes before they are deployed to production. Defaults to false<br>  - start\_vm\_on\_connect:              (optional) Enables or disables the Start VM on Connection Feature. Defaults to false<br>  - custom\_rdp\_properties             (optional) A valid custom RDP properties string for the Virtual Desktop Host Pool. Defaults to null<br>  - personal\_desktop\_assignment\_type: (optional) How AVD will select an available host and assign it to an user. Valid values are Automatic and Direct. Defaults to null<br>  - maximum\_sessions\_allowed:         (optional) A valid integer value from 0 to 999999 for the maximum number of users that have concurrent sessions on a session host. Defaults to null<br>  - preferred\_app\_group\_type:         (optional) Option to specify the preferred Application Group type for the Virtual Desktop Host Pool. Valid options are None, Desktop or RailApplications. Default is Desktop<br>  - scheduled\_agent\_updates:          (optional) A block as defined bellow<br>    - timezone:                       (optional) Specifies the time zone in which the agent update schedule will apply. Default is UTC<br>    - use\_session\_host\_timezone:      (optional) Specifies whether scheduled agent updates should be applied based on the timezone of the affected session host. If configured then this setting overrides timezone. Default is false<br>    - day\_of\_week:                    (optional) The day of the week on which agent updates should be performed. Possible values are Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, and Sunday<br>    - hour\_of\_day:                    (optional) The hour of day the update window should start. The update is a 2 hour period following the hour provided. The value should be provided as a number between 0 and 23. Defaults to 22<br>  - aadjoin:                          (optional) Define if VMs are Azure AD Joined. Defaults to false<br>  - aad\_scope\_id                      (optional) If aadjoin is set to true, you should provide the Resource Group or Subscription ID to grant 'Virtual Machine Administrator Login' and/or 'Virtual Machine User Login'. It is recommended to use the Resource Group ID where VMs were provisioned | <pre>object({<br>    name                             = string<br>    friendly_name                    = optional(string, null)<br>    description                      = optional(string, null)<br>    type                             = optional(string, "Pooled")<br>    load_balancer_type               = optional(string, "BreadthFirst")<br>    validate_environment             = optional(bool, false)<br>    start_vm_on_connect              = optional(bool, false)<br>    custom_rdp_properties            = optional(string, null)<br>    personal_desktop_assignment_type = optional(string, null)<br>    maximum_sessions_allowed         = optional(string, null)<br>    preferred_app_group_type         = optional(string, "Desktop")<br>    scheduled_agent_updates = optional(object({<br>      timezone                  = optional(string, "UTC")<br>      use_session_host_timezone = optional(bool, false)<br>      day_of_week               = optional(string, "Saturday")<br>      hour_of_day               = optional(number, 22)<br>    }), null)<br>    session_host_ids = map(string)<br>    aadjoin          = optional(bool, false)<br>    aad_scope_id     = optional(string, null)<br>  })</pre> | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | The region where the VM will be created. This parameter is required | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which the resources will be created. This parameter is required | `string` | n/a | yes |
| <a name="input_scaling_plan"></a> [scaling\_plan](#input\_scaling\_plan) | - name:                                   (required) The name which should be used for this Virtual Desktop Scaling Plan <br>  - enabled:                                (optional) Specifies if the scaling plan is enabled or disabled for the HostPool<br>  - friendly\_name:                          (optional) Friendly name of the Scaling Plan<br>  - description:                            (optional) A description of the Scaling Plan<br>  - timezone:                               (optional) Specifies the Time Zone which should be used by the Scaling Plan for time based events. Defaults to UTC<br>  - exclusion\_tag:                          (optional) he name of the tag associated with the VMs you want to exclude from autoscaling<br>  - schedule:                               (required) A block as defined bellow<br>    - days\_of\_week:                         (optional) A list of Days of the Week on which this schedule will be used. Defaults to '["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]'<br>    - off\_peak\_start\_time:                  (optional) The time at which Off-Peak scaling will begin. This is also the end-time for the Ramp-Down period. Defaults to 20:00<br>    - off\_peak\_load\_balancing\_algorithm:    (optional) The load Balancing Algorithm to use during Off-Peak Hours. Possible values are DepthFirst and BreadthFirst. Defaults to DepthFirst<br>    - peak\_start\_time:                      (optional) The time at which Peak scaling will begin. This is also the end-time for the Ramp-Up period. Defaults to 09:00<br>    - peak\_load\_balancing\_algorithm:        (optional) The load Balancing Algorithm to use during Peak Hours. Possible values are DepthFirst and BreadthFirst. Defaults to DepthFirst<br>    - ramp\_up\_capacity\_threshold\_percent:   (optional) This is the value of percentage of used host pool capacity that will be considered to evaluate whether to turn on/off virtual machines during the ramp-up and peak hours. Defaults to 60<br>    - ramp\_up\_load\_balancing\_algorithm:     (optional) The load Balancing Algorithm to use during the Ramp-Up period. Possible values are DepthFirst and BreadthFirst.Defaults to BreadthFirst<br>    - ramp\_up\_start\_time:                   (optional) The time at which Ramp-Up scaling will begin. This is also the end-time for the Ramp-Up period. Defaults to 08:00<br>    - ramp\_up\_minimum\_hosts\_percent:        (optional) Specifies the minimum percentage of session host virtual machines to start during ramp-up for peak hours. Defauls to 20<br>    - ramp\_down\_capacity\_threshold\_percent: (optional) This is the value in percentage of used host pool capacity that will be considered to evaluate whether to turn on/off virtual machines during the ramp-down and off-peak hours. Defaults to 90<br>    - ramp\_down\_force\_logoff\_users:         (optional) Whether users will be forced to log-off session hosts once the ramp\_down\_wait\_time\_minutes value has been exceeded during the Ramp-Down period. Defaults to true<br>    - ramp\_down\_load\_balancing\_algorithm:   (optional) The load Balancing Algorithm to use during the Ramp-Down period. Possible values are DepthFirst and BreadthFirst. Defaults to DepthFirst<br>    - ramp\_down\_minimum\_hosts\_percent:      (optional) The minimum percentage of session host virtual machines that you would like to get to for ramp-down and off-peak hours. Defaults to 10<br>    - ramp\_down\_notification\_message:       (optional) The notification message to send to users during Ramp-Down period when they are required to log-off. Defaults to "You will be logged off in 30 min. Make sure to save your work."<br>    - ramp\_down\_start\_time:                 (optional) The time at which Ramp-Down scaling will begin. This is also the end-time for the Ramp-Up period. Defaults to 18:00<br>    - ramp\_down\_stop\_hosts\_when:            (optional) Controls Session Host shutdown behaviour during Ramp-Down period. Session Hosts can either be shutdown when all sessions on the Session Host have ended, or when there are no Active sessions left on the Session Host. Possible values are ZeroSessions and ZeroActiveSessions. Default to ZeroSessions<br>    - ramp\_down\_wait\_time\_minutes:          (optional) The number of minutes during Ramp-Down period that autoscale will wait after setting the session host VMs to drain mode, notifying any currently signed in users to save their work before forcing the users to logoff. Defaults to 30 | <pre>object({<br>    name          = string<br>    enabled       = optional(bool, true)<br>    friendly_name = optional(string, null)<br>    description   = optional(string, null)<br>    timezone      = optional(string, "UTC")<br>    exclusion_tag = optional(string, null)<br>    schedule = map(object({<br>      days_of_week                         = optional(list(string), ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"])<br>      off_peak_start_time                  = optional(string, "20:00")<br>      off_peak_load_balancing_algorithm    = optional(string, "DepthFirst")<br>      peak_start_time                      = optional(string, "09:00")<br>      peak_load_balancing_algorithm        = optional(string, "DepthFirst")<br>      ramp_up_capacity_threshold_percent   = optional(number, 60)<br>      ramp_up_load_balancing_algorithm     = optional(string, "BreadthFirst")<br>      ramp_up_start_time                   = optional(string, "08:00")<br>      ramp_up_minimum_hosts_percent        = optional(number, 20)<br>      ramp_down_capacity_threshold_percent = optional(number, 90)<br>      ramp_down_force_logoff_users         = optional(bool, true)<br>      ramp_down_load_balancing_algorithm   = optional(string, "DepthFirst")<br>      ramp_down_minimum_hosts_percent      = optional(number, 10)<br>      ramp_down_notification_message       = optional(string, "You will be logged off in 30 min. Make sure to save your work.")<br>      ramp_down_start_time                 = optional(string, "18:00")<br>      ramp_down_stop_hosts_when            = optional(string, "ZeroSessions")<br>      ramp_down_wait_time_minutes          = optional(number, 30)<br>    }))<br>  })</pre> | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to be applied to resources. | `map(string)` | `{}` | no |
| <a name="input_workspace"></a> [workspace](#input\_workspace) | Workspace parameters. This parameter is required'<br>  - name:                          (required) The name of the Virtual Desktop Workspace<br>  - friendly\_name:                 (optional) A friendly name for the Virtual Desktop Workspace<br>  - description:                   (optional) A description for the Virtual Desktop Workspace<br>  - public\_network\_access\_enabled: (optional) Whether public network access is allowed for this Virtual Desktop Workspace. Defaults to true | <pre>object({<br>    name                          = string<br>    friendly_name                 = optional(string, null)<br>    description                   = optional(string, null)<br>    public_network_access_enabled = optional(bool, true)<br>  })</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_groups"></a> [application\_groups](#output\_application\_groups) | Application group names and ids |
| <a name="output_applications"></a> [applications](#output\_applications) | Application names and ids |
| <a name="output_host_pool_id"></a> [host\_pool\_id](#output\_host\_pool\_id) | Host Pool ID |
| <a name="output_host_pool_name"></a> [host\_pool\_name](#output\_host\_pool\_name) | Host Pool name |
| <a name="output_validate_application_groups"></a> [validate\_application\_groups](#output\_validate\_application\_groups) | n/a |
| <a name="output_validate_scaling_plan"></a> [validate\_scaling\_plan](#output\_validate\_scaling\_plan) | n/a |
| <a name="output_workspace_id"></a> [workspace\_id](#output\_workspace\_id) | Workspace ID |
| <a name="output_workspace_name"></a> [workspace\_name](#output\_workspace\_name) | Workspace name |

## Examples
```hcl
module "avd" {
  source              = "jsathler/azure-virtual-desktop/azurerm"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  workspace = {
    name          = "avdpooled-example"
    friendly_name = "AVD Pooled Workspace"
  }

  host_pool = {
    name                  = "avdpooled-example"
    friendly_name         = "AVD Pooled Pool"
    session_host_ids      = { for vm in module.sessionhosts : vm.name => vm.id }
    custom_rdp_properties = "targetisaadjoined:i:1"
    aadjoin               = true
    aad_scope_id          = azurerm_resource_group.default.id
    validate_environment  = true
  }

  application_groups = {
    avdpooled-desktop = {
      friendly_name                = "AVD Pooled Desktop"
      default_desktop_display_name = "Desktop"
      type                         = "Desktop"
      assignment_ids               = [azuread_group.desktop_users.object_id]
      admin_ids                    = [azuread_group.admins.object_id]
    }
    avdpooled-apps = {
      friendly_name  = "AVD Pooled Apps"
      assignment_ids = [azuread_group.app_users.object_id]
      admin_ids      = [azuread_group.admins.object_id]
      applications = {
        Microsoft-Edge = {
          friendly_name = "Microsoft Edge"
          path          = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
          icon_path     = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
        }
        WordPad = {
          friendly_name = "WordPad"
          path          = "C:\\Program Files\\Windows NT\\Accessories\\wordpad.exe"
          icon_path     = "C:\\Program Files\\Windows NT\\Accessories\\wordpad.exe"
        }
      }
    }
  }
}
```
More examples in ./examples folder
<!-- END_TF_DOCS -->