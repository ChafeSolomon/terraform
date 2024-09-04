resource "azuread_user" "users" {
  for_each = { for user in local.json_data : user.display_name => user }
  display_name = each.value.display_name
  user_principal_name = each.value.user_principal_name
}