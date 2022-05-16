module "iosxe_evpn_overlay" {
  source  = "netascode/evpn-overlay/iosxe"
  version = ">= 0.1.0"

  leafs                = ["LEAF-1", "LEAF-2"]
  spines               = ["SPINE-1", "SPINE-2"]
  underlay_loopback_id = 0

  underlay_loopbacks = [
    {
      device       = "SPINE-1",
      ipv4_address = "10.1.100.1"
    },
    {
      device       = "SPINE-2",
      ipv4_address = "10.1.100.2"
    },
    {
      device       = "LEAF-1",
      ipv4_address = "10.1.100.3"
    },
    {
      device       = "LEAF-2",
      ipv4_address = "10.1.100.4"
    }
  ]

  bgp_asn = 65000

  l2_services = [
    {
      id                   = 101
      ipv4_multicast_group = "225.0.0.101"
      ip_learning          = true
    },
    {
      id = 102
    }
  ]

  l3_services = [
    {
      name = "green"
      id   = 1000
      svis = [
        {
          id                       = 1001
          ipv4_address             = "172.16.1.1"
          ipv4_mask                = "255.255.255.0"
          ipv4_multicast_group     = "225.0.1.1"
          ip_learning              = true
          re_originate_route_type5 = true
        }
      ]
    },
    {
      name = "blue"
      id   = 1010
      svis = [
        {
          id           = 1011
          ipv4_address = "172.17.1.1"
          ipv4_mask    = "255.255.255.0"
        }
      ]
    }
  ]
}
