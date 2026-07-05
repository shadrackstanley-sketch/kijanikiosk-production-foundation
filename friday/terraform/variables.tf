variable "servers" {
  description = "Map of KijaniKiosk servers"

  type = map(object({
    image  = string
    cpus   = number
    memory = string
    disk   = string
  }))
}
