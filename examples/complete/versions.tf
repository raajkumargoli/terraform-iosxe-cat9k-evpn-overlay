terraform {
  required_version = ">= 1.3.0"

  required_providers {
    iosxe = {
      source  = "ciscodevnet/iosxe"
      version = "~>0.5.10"
    }
  }
}
