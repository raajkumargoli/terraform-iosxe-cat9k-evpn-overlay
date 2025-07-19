
# ciscoevpn provider settings
provider "iosxe" {
  devices  = local.devices
  username = var.username
  password = var.password
  insecure = var.insecure
}

module "iosxe_evpn_overlay" {
  source  = "./modules/iosxe_evpn_overlay"

  vtep_loopback_id     = 0
  leafs                = toset(keys(local.iosxe_leafs))
  spines               = toset(keys(local.iosxe_spines))
  underlay_loopback_id = 0

  underlay_loopbacks = [
    {
      device       = "SPINE-1",
      ipv4_address = "172.170.2.1"
    },
    {
      device       = "SPINE-2",
      ipv4_address = "172.170.2.2"
    },
    {
      device       = "LEAF-1",
      ipv4_address = "172.170.1.1"
    },
    {
      device       = "LEAF-2",
      ipv4_address = "172.170.1.2"
    },
    {
      device       = "LEAF-3",
      ipv4_address = "172.170.1.3"
    },
    {
      device       = "LEAF-4",
      ipv4_address = "172.170.1.4"
    },
  ]

  bgp_asn = 65000

  l3_services = [
    {
      name = "GREEN",
      id   = 1000
    },
    {
      name = "BLUE",
      id   = 1010
    }
  ]

  l2_services = [
    {
      name                 = "L2_101",
      id                   = 101,
      ipv4_multicast_group = "225.0.0.101",
      ip_learning          = false
    },
    {
      name = "L2_102",
      id   = 102
    },
    {
      name                     = "GREEN_1001",
      id                       = 1001,
      ipv4_multicast_group     = "225.0.1.1",
      l3_service               = "GREEN",
      ipv4_address             = "172.16.1.1",
      ipv4_mask                = "255.255.255.0",
      ip_learning              = false,
      re_originate_route_type5 = true
    },
    {
      name         = "BLUE_1011",
      id           = 1011,
      l3_service   = "BLUE",
      ipv4_address = "172.17.1.1",
      ipv4_mask    = "255.255.255.0"
    }
  ]
}

resource "iosxe_restconf" "anycast_gateway_mac_auto" {
  count    = var.enable_anycast_gateway_mac_auto ? length(keys(local.iosxe_leafs)) : 0
  device   = element(keys(local.iosxe_leafs), count.index)
  path     = "Cisco-IOS-XE-native:native/l2vpn/Cisco-IOS-XE-l2vpn:evpn_cont/evpn/anycast-gateway/mac"
  attributes = {
    auto = ""
  }
}
