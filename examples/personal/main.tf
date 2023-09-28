provider "azurerm" {
  features {}
}

locals {
  session_hosts = ["personalshost01", "personalshost02", "personalshost03"]
  azs           = [1, 2, 3]
}

resource "azurerm_resource_group" "default" {
  name     = "avdpersonal-example-rg"
  location = "NorthEurope"
}

module "avd-vnet" {
  source              = "jsathler/network/azurerm"
  version             = "0.0.1"
  name                = "avd"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  address_space       = ["10.0.0.0/16"]

  subnets = {
    default = {
      address_prefixes   = ["10.0.0.0/24"]
      nsg_create_default = true
    }
  }
}

resource "random_password" "default" {
  length = 21
}

module "sessionhosts" {
  for_each             = toset(local.session_hosts)
  source               = "jsathler/virtualmachine/azurerm"
  version              = "0.1.1"
  name                 = each.key
  location             = azurerm_resource_group.default.location
  resource_group_name  = azurerm_resource_group.default.name
  local_admin_name     = "localadmin"
  local_admin_password = random_password.default.result
  subnet_id            = [module.avd-vnet.subnet_ids.default-snet]
  availability_zone    = element(local.azs, index(local.session_hosts, each.key) % length(local.azs))
  azuread_join         = true
  identity_type        = "SystemAssigned"
  license_type         = "Windows_Client"
  os_type              = "windows"
  image_publisher      = "microsoftwindowsdesktop"
  image_offer          = "windows-11"
  image_sku            = "win11-22h2-avd"
}

data "azurerm_client_config" "default" {}

resource "azuread_group" "desktop_users" {
  display_name     = "avdpersonal-desktopusers"
  owners           = [data.azurerm_client_config.default.object_id]
  security_enabled = true
  members = [
    data.azurerm_client_config.default.object_id
  ]
}

resource "azuread_group" "app_users" {
  display_name     = "avdpersonal-appusers"
  owners           = [data.azurerm_client_config.default.object_id]
  security_enabled = true
  members = [
    data.azurerm_client_config.default.object_id
  ]
}

resource "azuread_group" "admins" {
  display_name     = "avdpersonal-admins"
  owners           = [data.azurerm_client_config.default.object_id]
  security_enabled = true
  members = [
    data.azurerm_client_config.default.object_id
  ]
}

module "avd" {
  source              = "../../"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  workspace = {
    name          = "avdpersonal-example"
    friendly_name = "AVD Personal Workspace"
  }

  host_pool = {
    name                             = "avdpersonal-example"
    friendly_name                    = "AVD Personal Pool"
    session_host_ids                 = { for vm in module.sessionhosts : vm.name => vm.id }
    custom_rdp_properties            = "targetisaadjoined:i:1;"
    aadjoin                          = true
    aad_scope_id                     = azurerm_resource_group.default.id
    validate_environment             = true
    type                             = "Personal"
    load_balancer_type               = "Persistent"
    personal_desktop_assignment_type = "Automatic"
  }

  #AVD Personal can contain only one application group of Desktop or RemoteApp type
  application_groups = {
    avdpersonal-desktop = {
      friendly_name                = "AVD Personal Desktop"
      default_desktop_display_name = "Desktop"
      type                         = "Desktop"
      assignment_ids               = [azuread_group.desktop_users.object_id]
      admin_ids                    = [azuread_group.admins.object_id]
    }
  }
}

output "avd" {
  value = module.avd
}

output "sessionhosts" {
  value = module.sessionhosts
}
