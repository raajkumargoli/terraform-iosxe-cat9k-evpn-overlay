terraform {
  required_version = ">= 1.1.0"

  required_providers {
    iosxe = {
      source  = "netascode/iosxe"
      version = ">=0.1.7"
    }
  }

  experiments = [module_variable_optional_attrs]
}
