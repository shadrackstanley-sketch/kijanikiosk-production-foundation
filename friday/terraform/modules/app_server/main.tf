resource "null_resource" "server" {
  triggers = {
    name   = var.name
    image  = var.image
    cpus   = var.cpus
    memory = var.memory
    disk   = var.disk
  }
}
