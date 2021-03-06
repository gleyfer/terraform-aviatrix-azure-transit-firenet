#Transit VPC
resource "aviatrix_vpc" "default" {
  cloud_type           = 8
  name                 = local.name
  region               = var.region
  cidr                 = var.cidr
  account_name         = var.account
  aviatrix_firenet_vpc = true
  aviatrix_transit_vpc = false
}

#Transit GW
resource "aviatrix_transit_gateway" "default" {
  enable_active_mesh               = var.active_mesh
  cloud_type                       = 8
  vpc_reg                          = var.region
  gw_name                          = local.name
  gw_size                          = var.insane_mode ? var.insane_instance_size : var.instance_size
  vpc_id                           = aviatrix_vpc.default.vpc_id
  account_name                     = var.account
  subnet                           = local.subnet
  ha_subnet                        = var.ha_gw ? local.ha_subnet : null
  insane_mode                      = var.insane_mode
  enable_transit_firenet           = true
  ha_gw_size                       = var.ha_gw ? (var.insane_mode ? var.insane_instance_size : var.instance_size) : null
  connected_transit                = var.connected_transit
  bgp_manual_spoke_advertise_cidrs = var.bgp_manual_spoke_advertise_cidrs
  enable_learned_cidrs_approval    = var.learned_cidr_approval
  enable_segmentation              = var.enable_segmentation
  single_az_ha                     = var.single_az_ha
  single_ip_snat                   = var.single_ip_snat
  enable_advertise_transit_cidr    = var.enable_advertise_transit_cidr
  bgp_polling_time                 = var.bgp_polling_time
  bgp_ecmp                         = var.bgp_ecmp
}

#Single instance
resource "aviatrix_firewall_instance" "firewall_instance" {
  count                  = var.ha_gw ? 0 : 1
  firewall_name          = "${local.name}-fw"
  firewall_size          = var.fw_instance_size
  vpc_id                 = aviatrix_vpc.default.vpc_id
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image_version
  egress_subnet          = aviatrix_vpc.default.subnets[0].cidr
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  username               = local.is_checkpoint ? "admin" : var.firewall_username
  password               = local.is_checkpoint ? var.checkpoint_password : ""
  management_subnet      = local.is_palo ? aviatrix_vpc.default.subnets[2].cidr : ""
}

#Dual instance
resource "aviatrix_firewall_instance" "firewall_instance_1" {
  count                  = var.ha_gw ? 1 : 0
  firewall_name          = "${local.name}-fw1"
  firewall_size          = var.fw_instance_size
  vpc_id                 = aviatrix_vpc.default.vpc_id
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image_version
  egress_subnet          = aviatrix_vpc.default.subnets[0].cidr
  firenet_gw_name        = aviatrix_transit_gateway.default.gw_name
  username               = local.is_checkpoint ? "admin" : var.firewall_username
  password               = local.is_checkpoint ? var.checkpoint_password : ""
  management_subnet      = local.is_palo ? aviatrix_vpc.default.subnets[2].cidr : ""
}

resource "aviatrix_firewall_instance" "firewall_instance_2" {
  count                  = var.ha_gw ? 1 : 0
  firewall_name          = "${local.name}-fw2"
  firewall_size          = var.fw_instance_size
  vpc_id                 = aviatrix_vpc.default.vpc_id
  firewall_image         = var.firewall_image
  firewall_image_version = var.firewall_image_version
  egress_subnet          = aviatrix_vpc.default.subnets[1].cidr
  firenet_gw_name        = "${aviatrix_transit_gateway.default.gw_name}-hagw"
  username               = local.is_checkpoint ? "admin" : var.firewall_username
  password               = local.is_checkpoint ? var.checkpoint_password : ""
  management_subnet      = local.is_palo ? aviatrix_vpc.default.subnets[3].cidr : ""
}

resource "aviatrix_firenet" "firenet_single" {
  count              = var.ha_gw ? 0 : 1
  vpc_id             = aviatrix_vpc.default.vpc_id
  inspection_enabled = var.inspection_enabled
  egress_enabled     = var.egress_enabled
  firewall_instance_association {
    firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
    instance_id          = aviatrix_firewall_instance.firewall_instance[0].instance_id
    vendor_type          = "Generic"
    firewall_name        = aviatrix_firewall_instance.firewall_instance[0].firewall_name
    lan_interface        = aviatrix_firewall_instance.firewall_instance[0].lan_interface
    management_interface = null
    egress_interface     = aviatrix_firewall_instance.firewall_instance[0].egress_interface
    attached             = var.attached
  }
}

resource "aviatrix_firenet" "firenet_ha" {
  count              = var.ha_gw ? 1 : 0
  vpc_id             = aviatrix_vpc.default.vpc_id
  inspection_enabled = var.inspection_enabled
  egress_enabled     = var.egress_enabled
  firewall_instance_association {
    firenet_gw_name      = aviatrix_transit_gateway.default.gw_name
    instance_id          = aviatrix_firewall_instance.firewall_instance_1[0].instance_id
    vendor_type          = "Generic"
    firewall_name        = aviatrix_firewall_instance.firewall_instance_1[0].firewall_name
    lan_interface        = aviatrix_firewall_instance.firewall_instance_1[0].lan_interface
    management_interface = null
    egress_interface     = aviatrix_firewall_instance.firewall_instance_1[0].egress_interface
    attached             = var.attached
  }
  firewall_instance_association {
    firenet_gw_name      = "${aviatrix_transit_gateway.default.gw_name}-hagw"
    instance_id          = aviatrix_firewall_instance.firewall_instance_2[0].instance_id
    vendor_type          = "Generic"
    firewall_name        = aviatrix_firewall_instance.firewall_instance_2[0].firewall_name
    lan_interface        = aviatrix_firewall_instance.firewall_instance_2[0].lan_interface
    management_interface = null
    egress_interface     = aviatrix_firewall_instance.firewall_instance_2[0].egress_interface
    attached             = var.attached
  }
}
