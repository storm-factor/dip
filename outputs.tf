
#output "internal_ip_vm1" {
#  value = yandex_compute_instance.vm1.network_interface.0.ip_address
#}
#output "internal_ip_vm2" {
#  value = yandex_compute_instance.vm2.network_interface.0.ip_address
#}
#output "internal_ip_elastic" {
#  value = yandex_compute_instance.vm_elastic.network_interface.0.ip_address
#}
#output "internal_ip_bastion" {
#  value = yandex_compute_instance.bastion.network_interface.0.ip_address
#}

output "external_out_address_bastion" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}
output "external_out_address_zabbix" {
  value = yandex_compute_instance.vm_zabbix.network_interface.0.nat_ip_address
}
output "external_out_address_kibana" {
  value = yandex_compute_instance.vm_kibana.network_interface.0.nat_ip_address
}


output "app_load_balancer_ip_address" {
  value = yandex_alb_load_balancer.ya_load_balancer.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}
