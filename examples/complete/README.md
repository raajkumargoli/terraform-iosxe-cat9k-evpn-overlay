# Cisco IOS-XE EVPN Overlay Terraform Module

This project provides a Terraform module to configure an EVPN overlay on Cisco IOS-XE devices.

## Project Overview

This Terraform module automates the configuration of an EVPN-VXLAN fabric on Cisco IOS-XE devices. It simplifies the deployment of a scalable and resilient network by managing the configuration of leafs and spines, underlay and overlay networking, and L2/L3 services.

## Prerequisites

Before using this module, ensure you have the following:

*   Terraform v0.13 or later
*   Access to Cisco IOS-XE devices with RESTCONF enabled
*   Credentials for the IOS-XE devices

## Configuration

The module is configured through variables defined in the `settings.tf` file. Here are the key variables:

*   `username`: The username for the IOS-XE devices.
*   `password`: The password for the IOS-XE devices.
*   `insecure`: A boolean to enable/disable insecure HTTPS connections.
*   `timeout`: The timeout for the IOS-XE client.
*   `iosxe_spines`: A map of spine devices, including their name and connection details.
*   `iosxe_leafs`: A map of leaf devices, including their name and connection details.
*   `iosxe_borders`: A list of devices to be configured as borders (currently unused in this example).
*   `enable_anycast_gateway_mac_auto`: A boolean to enable/disable the `anycast-gateway mac auto` configuration.

## Customizations to `iosxe_evpn_overlay` Module

This repository utilizes a locally sourced version of the `netascode/evpn-overlay/iosxe` Terraform module, located at `./modules/iosxe_evpn_overlay`. This local sourcing allows for specific customizations that are not present in the upstream module.

The following modifications have been applied:

*   **VRF Route Distinguisher (RD) Format:** The RD for VRFs is now derived using an IP-based format (`underlay_loopback_ipv4:ID`) instead of the default ASN-based format.
*   **EVPN Instance RD and Route Targets:** The `vlan_based_rd`, `vlan_based_route_target_import`, and `vlan_based_route_target_export` attributes have been removed from the `iosxe_evpn_instance` resource. The device will now auto-generate these values.
*   **BGP Address Family VRF Configuration:** The `advertise l2vpn evpn`, `redistribute connected`, and `redistribute static` commands are now explicitly configured for both IPv4 and IPv6 address families within VRFs.
*   **Per-VRF Custom Route Targets:** The `l3_services` variable now supports optional `rt_import` and `rt_export` attributes. This allows you to specify custom route targets for import and export on a per-VRF basis. If these are not provided, the route targets will be derived from the BGP ASN and L3 service ID.

    **Example of `l3_services` with custom route targets:**

    ```terraform
    l3_services = [
      {
        name = "GREEN",
        id   = 1000
      },
      {
        name = "BLUE",
        id   = 1010
      },
      {
        name = "yellow",
        id   = 1020,
        rt_import = ["65000:1234"],
        rt_export = ["65000:1234"]
      }
    ]
    ```

## Usage

To use this module, follow these steps:

1.  **Initialize Terraform:**

    ```bash
    terraform init
    ```

2.  **Review the plan:**

    ```bash
    terraform plan
    ```

3.  **Apply the configuration:**

    ```bash
    terraform apply
    ```

To destroy the resources created by this module, run:

```bash
terraform destroy
```

## Optional Features

### Anycast Gateway MAC Auto

This feature configures `anycast-gateway mac auto` on the leaf devices. It is disabled by default. This is available with 17.15 IOS-XE code. Make sure your SW is 17.15 or later when you enable this.

To enable this feature, set the `enable_anycast_gateway_mac_auto` variable to `true` in your `settings.tf` file or by using a `.tfvars` file.

**Example `terraform.tfvars`:**

```
enable_anycast_gateway_mac_auto = true
```
