variable "environment" {
  description = "The environment to deploy (dev, test, prod)"
  type        = string
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
}

variable "app_name" {
  description = "Name of the App"
  type        = string
}

variable "sub_id" {
  type = string
  default = ""  # or leave it out if using the environment variable
}

variable "adminuser" {
  type = string
  default = ""  # or leave it out if using the environment variable
}

variable "adminpassword" {
  type = string
  default = ""  # or leave it out if using the environment variable
}

variable "vm_count" {
  type = number
  default = "1"  # or leave it out if using the environment variable
}