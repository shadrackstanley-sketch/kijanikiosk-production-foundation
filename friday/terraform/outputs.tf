output "server_names" {
  description = "Names of all KijaniKiosk servers"

  value = {
    for key, module_instance in module.app_server :
    key => module_instance.name
  }
}
