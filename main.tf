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

output "instance_ip_addr" {
  value = var.adc-lb.lb_name
}

#####
# Save config
#####
resource "citrixadc_nsconfig_save" "lb_save" {
  all        = true
  timestamp  = timestamp()
}