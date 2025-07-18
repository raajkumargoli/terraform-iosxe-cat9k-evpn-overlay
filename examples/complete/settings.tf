variable "username" {
  type        = string
  default     = "netadmin"
  description = "Cisco IOS-XE Username"
}

variable "password" {
  type        = string
  default     = "C1sc0dna"
  description = "Cisco IOS-XE Passwordd"
}

variable "insecure" {
  type        = bool
  default     = true
  description = "Cisco IOS-XE HTTPS insecure"
}

variable "timeout" {
  type        = number
  default     = 120
  description = "Cisco IOS-XE Client timeout"
}

locals {
  iosxe_spines = {
    SPINE-1 = {
      url      = "https://172.26.193.242"
      username = "netadmin"
      password = "C1sc0dna"
      insecure = true
    }
    SPINE-2 = {
      url      = "https://172.26.193.243"
      username = "netadmin"
      password = "C1sc0dna"
      insecure = true
    }
  }
  iosxe_leafs = {
    LEAF-1 = {
      url      = "https://172.26.193.240"
      username = "netadmin"
      password = "C1sc0dna"
      insecure = true
    }
    LEAF-2 = {
      url      = "https://172.26.193.241"
      username = "netadmin"
      password = "C1sc0dna"
      insecure = true
    }
    LEAF-3 = {
      url      = "https://172.26.193.247"
      username = "netadmin"
      password = "C1sc0dna"
      insecure = true
    }
    LEAF-4 = {
      url      = "https://172.26.193.248"
      username = "netadmin"
      password = "C1sc0dna"
      insecure = true
    }
  }
  devices = concat(
    [for name, spine in local.iosxe_spines : {
      name     = name
      url      = spine.url
      username = spine.username
      password = spine.password
      insecure = spine.insecure
    }],
    [for name, leaf in local.iosxe_leafs : {
      name     = name
      url      = leaf.url
      username = leaf.username
      password = leaf.password
      insecure = leaf.insecure
    }]
  )
}

variable "iosxe_borders" {
  type        = list(string)
  default     = []
  description = "Cisco IOS-XE Devices as Borders"
}

variable "enable_anycast_gateway_mac_auto" {
  type        = bool
  default     = true
  description = "Enable anycast-gateway mac auto configuration"
}