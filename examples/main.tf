provider "azurerm" {
  features {}
  subscription_id = "0783ffe8-281d-407a-8b7f-c61da7adb25a"
}

resource "azurerm_resource_group" "default" {
  name     = "avd-example-rg"
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
      nsg_create_default = false
    }
  }
}

resource "random_password" "default" {
  length = 16
}

module "sessionhost-vms" {
  for_each = toset(["session01", "session02"])
  #source               = "jsathler/virtualmachine/azurerm"
  #version              = "0.0.6"
  source               = "/mnt/c/iac/public/terraform-azurerm-virtualmachine"
  name                 = each.key
  location             = azurerm_resource_group.default.location
  resource_group_name  = azurerm_resource_group.default.name
  local_admin_name     = "localadmin"
  local_admin_password = random_password.default.result
  subnet_id            = [module.avd-vnet.subnet_ids.default-snet]
  azuread_join         = true
  identity_type        = "SystemAssigned"
  license_type         = "Windows_Client"
  os_type              = "windows"
  image_publisher      = var.image.publisher
  image_offer          = var.image.offer
  image_sku            = var.image.sku
}

data "azurerm_client_config" "default" {}

module "avd" {
  source              = "../"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name

  workspace = {
    name          = "jumpbox-example"
    friendly_name = "Jumpbox Workspace"
  }

  host_pool = {
    name             = "jumpbox-example"
    friendly_name    = "Jumpbox Pool"
    session_host_ids = [for vm in module.sessionhost-vms : vm.id]
  }

  application_groups = {
    jumpbox-desktop = {
      friendly_name  = "Jumpbox Desktop"
      type           = "Desktop"
      assignment_ids = [data.azurerm_client_config.default.object_id, "8f83c55d-0cf3-4aaa-b0fd-67d0dcb8a927"]
    }
    jumpbox-apps = {
      friendly_name  = "Jumpbox Apps"
      assignment_ids = [data.azurerm_client_config.default.object_id]
      applications = {
        Microsoft-Edge = {
          friendly_name = "Microsoft Edge"
          path          = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
          icon_path     = "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe"
        }
      }
    }
  }
}

output "avd" {
  value = module.avd
}

output "sessionhost-vms" {
  value = module.sessionhost-vms
}
