locals {
  resource_group       = "powervs-ipi-resource-group"
  vpc_region           = "eu-gb"
  vpc_zone             = "eu-gb-2"
  vpc_name             = "powervs-ipi"
  vpc_subnet_name      = "subnet2"
  cluster_id           = "hiro-lbpool"

  bootstrap_private_ip = "192.168.151.1"
  control_plane_ips    = ["192.168.151.2", "192.168.151.3", "192.168.151.4"] 
  api_servers          = var.expose_bootstrap ? concat([local.bootstrap_private_ip], local.control_plane_ips): local.control_plane_ips
  api_servers_count    = length(local.control_plane_ips) + (var.expose_bootstrap ? 1: 0)
}

provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = local.vpc_region
  zone             = local.vpc_zone
}

data "ibm_resource_group" "resource_group" {
  name = local.resource_group
}

data "ibm_is_subnet" "vpc_subnet" {
  name     = local.vpc_subnet_name
}

data "ibm_is_vpc" "vpc" {
  name = local.vpc_name
}

resource "ibm_is_security_group" "ocp_security_group" {
  name           = "${local.cluster_id}-ocp-sec-group"
  resource_group = data.ibm_resource_group.resource_group.id
  vpc            = data.ibm_is_vpc.vpc.id
  tags           = [local.cluster_id]
}

resource "ibm_is_lb" "load_balancer_int" {
  name            = "${local.cluster_id}-loadbalancer-int"
  resource_group  = data.ibm_resource_group.resource_group.id
  subnets         = [data.ibm_is_subnet.vpc_subnet.id]
  security_groups = [ibm_is_security_group.ocp_security_group.id]
  tags            = [local.cluster_id, "${local.cluster_id}-loadbalancer-int"]
  type            = "private"
}

resource "ibm_is_lb_pool" "machine_config_pool" {
  depends_on = [ibm_is_lb.load_balancer_int]

  name           = "machine-config-server"
  lb             = ibm_is_lb.load_balancer_int.id
  algorithm      = "round_robin"
  protocol       = "tcp"
  health_delay   = 60
  health_retries = 5
  health_timeout = 30
  health_type    = "tcp"
}

resource "ibm_is_lb_pool_member" "machine_config_member" {
  count      = local.api_servers_count

  lb             = ibm_is_lb.load_balancer_int.id
  pool           = ibm_is_lb_pool.machine_config_pool.id
  port           = 22623
  target_address = local.api_servers[count.index]
}

