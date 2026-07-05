module "app_server" {
  source = "./modules/app_server"

  for_each = var.servers

  name   = "kijanikiosk-${each.key}"
  image  = each.value.image
  cpus   = each.value.cpus
  memory = each.value.memory
  disk   = each.value.disk
}
