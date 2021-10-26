#******************************************
#                Network
#******************************************
variable "network_resource_prefix" {
  description = "Prefix for all subnet names"
  type        = string
  default     = "wsc-devops-exam-rg"
}

variable "network_resource_location" {
  description = "Location for Network Resource Group"
  type        = string
  default     = "West US"
}

variable "vnt_settings" {
  type = map(object({
    address_space = list(string)
    subnets = map(object({
      address_prefixes      = list(string)
      create_security_group = bool
      
    }))
  }))
  description = "vnt settings"
  default = {
    vnet-a = {
      address_space      = ["192.1.0.0/16"]
      subnets = {
        subnet-a = {
          address_prefixes      = ["192.1.0.0/24"]
          create_security_group = true
        }
      }
    }
    vnet-b = {
      address_space      = ["192.2.0.0/16"]
      subnets = {
        subnet-b = {
          address_prefixes      = ["192.2.0.0/24"]
          create_security_group = true
        }
      }
    }
    vnet-c = {
      address_space      = ["192.3.0.0/16"]
      subnets = {
        subnet-c = {
          address_prefixes      = ["192.3.0.0/24"]
          create_security_group = true
        }
      }
    }
  }
}