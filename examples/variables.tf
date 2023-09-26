variable "image" {
  type = object({
    offer     = optional(string, "windows-11")
    publisher = optional(string, "microsoftwindowsdesktop")
    sku       = optional(string, "win11-22h2-avd")
  })
  default  = {}
  nullable = false
}
