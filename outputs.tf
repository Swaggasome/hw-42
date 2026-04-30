output "external_ip" {
  value       = module.my_first_vm.external_ip
  description = "Внешний IP-адрес виртуальной машины"
}

output "vm_id" {
  value       = module.my_first_vm.vm_id
  description = "ID виртуальной машины"
}
