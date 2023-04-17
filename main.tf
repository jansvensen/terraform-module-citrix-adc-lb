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
# Save config
#####
resource "citrixadc_nsconfig_save" "lb_save" {
  all        = true
  timestamp  = timestamp()

  depends_on = [
      citrixadc_servicegroup.lb_servicegroup
  ]
}