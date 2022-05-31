locals {
  all                  = setunion(var.leafs, var.spines)
  leaf_spine_product   = { for ls in setproduct(var.leafs, var.spines) : "${ls[0]}/${ls[1]}" => ls }
  leaf_l3_services     = { for l in setproduct(var.leafs, var.l3_services) : "${l[0]}/${l[1].id}" => l }
  leaf_l2_services     = { for l in setproduct(var.leafs, var.l2_services) : "${l[0]}/${l[1].id}" => l }
  leaf_l2_services_svi = { for l in setproduct(var.leafs, var.l2_services) : "${l[0]}/${l[1].id}" => l if l[1].ipv4_address != null }
}

resource "iosxe_bgp" "bgp" {
  for_each = local.all

  device               = each.value
  asn                  = var.bgp_asn
  default_ipv4_unicast = false
  log_neighbor_changes = true
  router_id_loopback   = var.underlay_loopback_id

  depends_on = [var.underlay_loopbacks]
}

resource "iosxe_bgp_address_family_l2vpn" "bgp_l2vpn" {
  for_each = local.all

  device  = each.value
  asn     = iosxe_bgp.bgp[each.value].asn
  af_name = "evpn"
}

resource "iosxe_bgp_neighbor" "bgp_neighbor_leaf" {
  for_each = local.leaf_spine_product

  device                 = each.value[0]
  asn                    = iosxe_bgp.bgp[each.value[0]].asn
  ip                     = [for l in var.underlay_loopbacks : l.ipv4_address if each.value[1] == l.device][0]
  remote_as              = iosxe_bgp.bgp[each.value[0]].asn
  update_source_loopback = var.underlay_loopback_id
}

resource "iosxe_bgp_neighbor" "bgp_neighbor_spine" {
  for_each = local.leaf_spine_product

  device                 = each.value[1]
  asn                    = iosxe_bgp.bgp[each.value[1]].asn
  ip                     = [for l in var.underlay_loopbacks : l.ipv4_address if each.value[0] == l.device][0]
  remote_as              = iosxe_bgp.bgp[each.value[1]].asn
  update_source_loopback = var.underlay_loopback_id
}

resource "iosxe_bgp_l2vpn_evpn_neighbor" "bgp_l2vpn_evpn_neighbor_leaf" {
  for_each = local.leaf_spine_product

  device         = each.value[0]
  asn            = iosxe_bgp_address_family_l2vpn.bgp_l2vpn[each.value[0]].asn
  ip             = iosxe_bgp_neighbor.bgp_neighbor_leaf[each.key].ip
  activate       = true
  send_community = "both"
}

resource "iosxe_bgp_l2vpn_evpn_neighbor" "bgp_l2vpn_evpn_neighbor_spine" {
  for_each = local.leaf_spine_product

  device                 = each.value[1]
  asn                    = iosxe_bgp_address_family_l2vpn.bgp_l2vpn[each.value[1]].asn
  ip                     = iosxe_bgp_neighbor.bgp_neighbor_spine[each.key].ip
  activate               = true
  send_community         = "both"
  route_reflector_client = true
}

resource "iosxe_evpn" "evpn" {
  for_each = var.leafs

  device                    = each.value
  replication_type_static   = true
  mac_duplication_limit     = 20
  mac_duplication_time      = 10
  ip_duplication_limit      = 20
  ip_duplication_time       = 10
  router_id_loopback        = var.vtep_loopback_id
  default_gateway_advertise = true
  logging_peer_state        = true
  route_target_auto_vni     = true
}

resource "iosxe_evpn_instance" "l2_evpn_instance" {
  for_each = local.leaf_l2_services

  device                              = each.value[0]
  evpn_instance_num                   = each.value[1].id
  vlan_based_replication_type_ingress = each.value[1].ipv4_multicast_group == null ? true : null
  vlan_based_encapsulation            = "vxlan"
  vlan_based_rd                       = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  vlan_based_route_target_import      = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  vlan_based_route_target_export      = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  vlan_based_ip_local_learning_enable = each.value[1].ip_learning

  depends_on = [iosxe_evpn.evpn]
}

resource "iosxe_vlan_configuration" "l2_vlan_configuration" {
  for_each = local.leaf_l2_services

  device            = each.value[0]
  vlan_id           = each.value[1].id
  evpn_instance     = each.value[1].id
  evpn_instance_vni = each.value[1].id + 10000

  depends_on = [iosxe_evpn_instance.l2_evpn_instance]
}

resource "iosxe_interface_vlan" "l2_svi" {
  for_each = local.leaf_l2_services_svi

  device            = each.value[0]
  name              = each.value[1].id
  autostate         = false
  vrf_forwarding    = each.value[1].l3_service
  ipv4_address      = each.value[1].ipv4_address
  ipv4_address_mask = each.value[1].ipv4_mask

  depends_on = [iosxe_vrf.vrf]
}

resource "iosxe_vrf" "vrf" {
  for_each = local.leaf_l3_services

  device              = each.value[0]
  name                = each.value[1].name
  rd                  = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  address_family_ipv4 = true
  address_family_ipv6 = true
  ipv4_route_target_import = [{
    value = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  }]
  ipv4_route_target_import_stitching = [{
    value = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  }]
  ipv4_route_target_export = [{
    value = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  }]
  ipv4_route_target_export_stitching = [{
    value = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  }]
  ipv6_route_target_import = [{
    value = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  }]
  ipv6_route_target_import_stitching = [{
    value = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  }]
  ipv6_route_target_export = [{
    value = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  }]
  ipv6_route_target_export_stitching = [{
    value = "${iosxe_bgp.bgp[each.value[0]].asn}:${each.value[1].id}"
  }]
}

resource "iosxe_bgp_address_family_ipv4_vrf" "bgp_af_ipv4_vrf" {
  for_each = var.leafs

  device  = each.value
  asn     = iosxe_bgp.bgp[each.value].asn
  af_name = "unicast"
  vrfs = [for l3 in var.l3_services : {
    name                   = l3.name
    advertise_l2vpn_evpn   = true
    redistribute_connected = true
    redistribute_static    = true
  }]

  depends_on = [iosxe_vrf.vrf]
}

resource "iosxe_bgp_address_family_ipv6_vrf" "bgp_af_ipv6_vrf" {
  for_each = var.leafs

  device  = each.value
  asn     = iosxe_bgp.bgp[each.value].asn
  af_name = "unicast"
  vrfs = [for l3 in var.l3_services : {
    name                   = l3.name
    advertise_l2vpn_evpn   = true
    redistribute_connected = true
    redistribute_static    = true
  }]

  depends_on = [iosxe_vrf.vrf]
}

resource "iosxe_vlan_configuration" "l3_vlan_configuration" {
  for_each = local.leaf_l3_services

  device  = each.value[0]
  vlan_id = each.value[1].id
  vni     = each.value[1].id + 10000
}

resource "iosxe_interface_vlan" "l3_core_svi" {
  for_each = local.leaf_l3_services

  device         = each.value[0]
  name           = each.value[1].id
  autostate      = false
  vrf_forwarding = each.value[1].name
  unnumbered     = "Loopback${var.vtep_loopback_id}"

  depends_on = [iosxe_vrf.vrf]
}

resource "iosxe_interface_nve" "nve" {
  for_each = var.leafs

  device                         = each.value
  name                           = 1
  host_reachability_protocol_bgp = true
  source_interface_loopback      = var.vtep_loopback_id
  vnis = [for l2 in var.l2_services : {
    vni_range            = l2.id + 10000
    ingress_replication  = l2.ipv4_multicast_group == null ? true : null
    ipv4_multicast_group = l2.ipv4_multicast_group
  }]
  vni_vrfs = [for l3 in var.l3_services : {
    vni_range = l3.id + 10000
    vrf       = l3.name
  }]

  depends_on = [iosxe_vrf.vrf]
}
