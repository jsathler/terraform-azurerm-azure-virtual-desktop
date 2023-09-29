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
