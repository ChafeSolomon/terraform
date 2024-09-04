locals {
  user_files = fileset(path.module, "data/users/*.json")
  json_data  = [for f in local.user_files : jsondecode(file("${path.module}/${f}"))]
}

output name {
  value       = "${local.json_data}"
  sensitive   = false
  description = "description"
  depends_on  = []
}
