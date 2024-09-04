resource "azuread_user" "users" {
  for_each            = { for user in local.json_data : user.display_name => user }
  display_name        = each.value.display_name
  user_principal_name = each.value.user_principal_name
  password            = random_password.user_passwords[each.key].result
}

resource "random_password" "user_passwords" {
  for_each = { for user in local.json_data : user.display_name => user }
  length   = 16
  special  = true
  upper    = true
  lower    = true
  numeric   = true
}

# Create project RG
resource "azurerm_resource_group" "az104_rg" {
  name     = "AZ104"
  location = "eastus"
}
