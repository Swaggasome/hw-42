output "load_balancer_ip" {
  value       = yandex_alb_load_balancer.my_alb2.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
  description = "Internal IP address of the load balancer"
}

output "instance_group_id" {
  value       = yandex_compute_instance_group.app_group.id
  description = "ID of the instance group"
}

output "instance_group_target_group_id" {
  value       = yandex_compute_instance_group.app_group.application_load_balancer.0.target_group_id
  description = "ID of the target group managed by instance group"
}

output "instance_group_status" {
  value       = yandex_compute_instance_group.app_group.status
  description = "Current status of the instance group"
}
