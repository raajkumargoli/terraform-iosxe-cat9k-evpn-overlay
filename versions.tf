terraform {
  required_version = ">= 1.3.0"

  required_providers {
    iosxe = {
      source  = "netascode/iosxe"
      version = ">=0.1.7"
    }
  }
}
