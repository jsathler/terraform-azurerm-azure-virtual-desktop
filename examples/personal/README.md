# Azure Virtual Desktop Terraform example

## How to use this example
Terraform does not allow using values derived from resource attributes that cannot be determined until apply as key in "for_each", if we try to use it the following error is shown:

  The "for_each" set includes values derived from resource attributes that cannot be determined until apply, and so Terraform cannot determine the full set of keys that will identify the instances of this

Since we use the principal_id as part of keys on module, all principals (users and/or groups) should be created before running this example.

To bypass this situation on this example, execute the "terraform apply -target" to first create the Azure AD groups and them execute the terraform apply
  
  terraform apply -target="azuread_group.desktop_users" -target="azuread_group.app_users" -target="azuread_group.admins"