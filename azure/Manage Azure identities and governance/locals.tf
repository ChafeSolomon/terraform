locals {
  users       = fileset("${path.module}/data/users/", "*.json")
}

output names {
  for_each = fileset(path.module, "data/users/*")
  value       = local.users
  sensitive   = false
  description = "description"
  depends_on  = []
}
