<!-- BEGIN_TF_DOCS -->
[![Tests](https://github.com/netascode/terraform-iosxe-evpn-overlay/actions/workflows/test.yml/badge.svg)](https://github.com/netascode/terraform-iosxe-evpn-overlay/actions/workflows/test.yml)

# Terraform Cisco IOS-XE EVPN Overlay Module

This module can manage a Catalyst 9000 EVPN fabric overlay.

The following assumptions have been made:

- A working underlay network including VTEP loopbacks is pre-configured (e.g., using the [EVPN OSPF Underlay Terraform Module](https://registry.terraform.io/modules/netascode/evpn-ospf-underlay/iosxe))
- A single BGP AS is used for all devices with spines acting as route reflectors
- All services will be provisioned on all leafs
- No L2 or L3 access interfaces will be provisioned
- A `l2_service` refers to a single L2 VNI
- A `l3_service` refers to a single VRF and L3 VNI
- A `l3_service` SVI will be provisioned as an anycast gateway on all leafs with a corresponding L2 VNI
- If no `ipv4_multicast_group` is configured ingress replication will be used

## Examples

```hcl
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

  l3_services = [
    {
      name = "GREEN"
      id   = 1000
    },
    {
      name = "BLUE"
      id   = 1010
    }
  ]

  l2_services = [
    {
      name                 = "L2_101"
      id                   = 101
      ipv4_multicast_group = "225.0.0.101"
      ip_learning          = true
    },
    {
      name = "L2_102"
      id   = 102
    },
    {
      name                     = "GREEN_1001"
      id                       = 1001
      ipv4_multicast_group     = "225.0.1.1"
      l3_service               = "GREEN"
      ipv4_address             = "172.16.1.1"
      ipv4_mask                = "255.255.255.0"
      ip_learning              = true
      re_originate_route_type5 = true
    },
    {
      name         = "BLUE_1011"
      id           = 1011
      l3_service   = "BLUE"
      ipv4_address = "172.17.1.1"
      ipv4_mask    = "255.255.255.0"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.1.0 |
| <a name="requirement_iosxe"></a> [iosxe](#requirement\_iosxe) | >=0.1.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_iosxe"></a> [iosxe](#provider\_iosxe) | >=0.1.7 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_leafs"></a> [leafs](#input\_leafs) | List of leaf device names. This list of devices must also be added to the provider configuration. | `set(string)` | `[]` | no |
| <a name="input_spines"></a> [spines](#input\_spines) | List of spine device names. This list of devices must also be added to the provider configuration. | `set(string)` | `[]` | no |
| <a name="input_underlay_loopback_id"></a> [underlay\_loopback\_id](#input\_underlay\_loopback\_id) | Loopback ID used for underlay routing and BGP. | `number` | `0` | no |
| <a name="input_underlay_loopbacks"></a> [underlay\_loopbacks](#input\_underlay\_loopbacks) | List of underlay loopback interfaces. These loopbacks are assumed to be pre-configured on every device. | <pre>list(object({<br>    device       = string<br>    ipv4_address = string<br>  }))</pre> | `[]` | no |
| <a name="input_vtep_loopback_id"></a> [vtep\_loopback\_id](#input\_vtep\_loopback\_id) | Loopback ID used for VTEP loopbacks. These loopbacks are assumed to be pre-configured on all leafs. | `number` | `1` | no |
| <a name="input_bgp_asn"></a> [bgp\_asn](#input\_bgp\_asn) | BGP AS number. | `number` | `65000` | no |
| <a name="input_l3_services"></a> [l3\_services](#input\_l3\_services) | List of L3 services. `name` is the VRF name. `id` is the core-facing SVI VLAN ID. If no `ipv4_multicast_group` is specified, ingress replication will be used. | <pre>list(object({<br>    name = string<br>    id   = number<br>  }))</pre> | `[]` | no |
| <a name="input_l2_services"></a> [l2\_services](#input\_l2\_services) | List of L2 services. `id` is the access VLAN ID. If no `ipv4_multicast_group` is specified, ingress replication will be used. | <pre>list(object({<br>    name                     = string<br>    id                       = number<br>    ipv4_multicast_group     = optional(string)<br>    l3_service               = optional(string)<br>    ipv4_address             = optional(string)<br>    ipv4_mask                = optional(string)<br>    ip_learning              = optional(bool)<br>    re_originate_route_type5 = optional(bool)<br>  }))</pre> | `[]` | no |

## Outputs

No outputs.

## Resources

| Name | Type |
|------|------|
| [iosxe_bgp.bgp](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/bgp) | resource |
| [iosxe_bgp_address_family_ipv4_vrf.bgp_af_ipv4_vrf](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/bgp_address_family_ipv4_vrf) | resource |
| [iosxe_bgp_address_family_ipv6_vrf.bgp_af_ipv6_vrf](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/bgp_address_family_ipv6_vrf) | resource |
| [iosxe_bgp_address_family_l2vpn.bgp_l2vpn](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/bgp_address_family_l2vpn) | resource |
| [iosxe_bgp_l2vpn_evpn_neighbor.bgp_l2vpn_evpn_neighbor_leaf](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/bgp_l2vpn_evpn_neighbor) | resource |
| [iosxe_bgp_l2vpn_evpn_neighbor.bgp_l2vpn_evpn_neighbor_spine](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/bgp_l2vpn_evpn_neighbor) | resource |
| [iosxe_bgp_neighbor.bgp_neighbor_leaf](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/bgp_neighbor) | resource |
| [iosxe_bgp_neighbor.bgp_neighbor_spine](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/bgp_neighbor) | resource |
| [iosxe_evpn.evpn](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/evpn) | resource |
| [iosxe_evpn_instance.l2_evpn_instance](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/evpn_instance) | resource |
| [iosxe_interface_nve.nve](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/interface_nve) | resource |
| [iosxe_interface_vlan.l2_svi](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/interface_vlan) | resource |
| [iosxe_interface_vlan.l3_core_svi](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/interface_vlan) | resource |
| [iosxe_vlan_configuration.l2_vlan_configuration](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/vlan_configuration) | resource |
| [iosxe_vlan_configuration.l3_vlan_configuration](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/vlan_configuration) | resource |
| [iosxe_vrf.vrf](https://registry.terraform.io/providers/netascode/iosxe/latest/docs/resources/vrf) | resource |
<!-- END_TF_DOCS -->