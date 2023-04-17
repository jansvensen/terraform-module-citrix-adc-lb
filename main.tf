locals {
  httpprofilename = "http_prof_${var.adc-base.environmentname}"
  tcpprofilename  = "tcp_prof_${var.adc-base.environmentname}"
  sslprofilename  = "ssl_prof_${var.adc-base.environmentname}_fe_TLS1213"

}

#####
# Add LB Server
#####
resource "citrixadc_server" "lb_server" {
  count     = length(var.adc-lb.lb_srv_name)
  name      = "lb_srv_${element(var.adc-lb["lb_srv_name"],count.index)}"
  ipaddress = element(var.adc-lb["lb_srv_ip"],count.index)
}

#####
# Add LB Service Groups
#####
resource "citrixadc_servicegroup" "lb_servicegroup" {
  count             = length(var.adc-lb.lb_name)
  servicegroupname  = "lb_sg_${element(var.adc-lb["lb_name"],count.index)}_${element(var.adc-lb["lb_type"],count.index)}_${element(var.adc-lb["lb_port"],count.index)}"
  servicetype       = element(var.adc-lb["lb_type"],count.index)

  depends_on = [
    citrixadc_server.lb_server
  ]
}

#####
# Bind LB Server to Service Groups
#####
resource "citrixadc_servicegroup_servicegroupmember_binding" "lb_sg_server_binding" {
  count             = length(var.adc-lb.lb_name)
  servicegroupname  = "lb_sg_${element(var.adc-lb["lb_name"],count.index)}_${element(var.adc-lb["lb_type"],count.index)}_${element(var.adc-lb["lb_port"],count.index)}"
  servername        = "lb_srv_${element(var.adc-lb["lb_srv_name"],count.index)}"
  port              = element(var.adc-lb["lb_port"],count.index)

  depends_on = [
    citrixadc_servicegroup.lb_servicegroup
  ]
}

#####
# Add and configure LB vServer
#####
resource "citrixadc_lbvserver" "lb_vserver" {
  count           = length(var.adc-lb.lb_name)
  name            = "lb_vs_${element(var.adc-lb["lb_name"],count.index)}_${element(var.adc-lb["lb_type"],count.index)}_${element(var.adc-lb["lb_port"],count.index)}"

  servicetype     = element(var.adc-lb["lb_type"],count.index)
  ipv46           = var.adc-lb.lb_generic_lb-ip
  port            = var.adc-lb.lb_generic_lb-port
  lbmethod        = var.adc-lb.lb_generic_lbmethod
  persistencetype = var.adc-lb.lb_generic_persistencetype
  timeout         = var.adc-lb.lb_generic_timeout
  sslprofile      = element(var.adc-lb["lb_type"],count.index) == "SSL" ? local.sslprofilename : null
  httpprofilename = element(var.adc-lb["lb_type"],count.index) == "DNS" || element(var.adc-lb["lb_type"],count.index) == "TCP" ? null : local.httpprofilename
  tcpprofilename  = element(var.adc-lb["lb_type"],count.index) == "DNS" ? null : local.tcpprofilename

  depends_on = [
    citrixadc_servicegroup_servicegroupmember_binding.lb_sg_server_binding
  ]
}

#####
# Bind LB Service Groups to LB vServers
#####
resource "citrixadc_lbvserver_servicegroup_binding" "lb_vserver_sg_binding" {
  count             = length(var.adc-lb.lb_name)
  name              = "lb_vs_${element(var.adc-lb["lb_name"],count.index)}_${element(var.adc-lb["lb_type"],count.index)}_${element(var.adc-lb["lb_port"],count.index)}"
  servicegroupname  = "lb_sg_${element(var.adc-lb["lb_name"],count.index)}_${element(var.adc-lb["lb_type"],count.index)}_${element(var.adc-lb["lb_port"],count.index)}"

  depends_on = [
    citrixadc_lbvserver.lb_vserver
  ]
}

#####
# Save config
#####
resource "citrixadc_nsconfig_save" "lb_save" {
  all        = true
  timestamp  = timestamp()

  depends_on = [
      citrixadc_lbvserver_servicegroup_binding.lb_vserver_sg_binding
  ]
}