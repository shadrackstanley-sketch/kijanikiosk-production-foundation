variable "name" {
  description = "Name of the Multipass server"
  type        = string
}

variable "image" {
  description = "Ubuntu image used for the Multipass server"
  type        = string
}

variable "cpus" {
  description = "Number of CPUs assigned to the server"
  type        = number
}

variable "memory" {
  description = "Memory assigned to the server"
  type        = string
}

variable "disk" {
  description = "Disk assigned to the server"
  type        = string
}
