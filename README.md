# Azure Virtual Desktop Terraform module

Terraform module which creates Azure Virtual Desktop resources on Azure.

These types of resources are supported:

* [Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/virtual-desktop/overview)
* [Azure Virtual Desktop Host Pools](https://learn.microsoft.com/en-us/azure/virtual-desktop/terminology#host-pools)
* [Azure Virtual Desktop Application Groups](https://learn.microsoft.com/en-us/azure/virtual-desktop/terminology#application-groups)
* [Azure Virtual Desktop Workspaces](https://learn.microsoft.com/en-us/azure/virtual-desktop/terminology#workspaces)
* [Azure Virtual Desktop Scaling Plan*](https://learn.microsoft.com/en-us/azure/virtual-desktop/autoscale-scenarios#how-a-scaling-plan-works)
* [Azure RBAC](https://learn.microsoft.com/en-us/azure/role-based-access-control/overview)
* [Azure AD-joined virtual machines in Azure Virtual Desktop](https://learn.microsoft.com/en-us/azure/virtual-desktop/azure-ad-joined-session-hosts)

## Terraform versions

Terraform 1.5.6 and newer.

## Roadmap
 * [FSLogix profile containers](https://learn.microsoft.com/en-us/azure/virtual-desktop/fslogix-containers-azure-files)
 
## Notes

* Currently terraform only support creating scaling plan for Pooled Host Pool type (https://github.com/hashicorp/terraform-provider-azurerm/issues/22601)

## Usage

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

More samples in examples folder