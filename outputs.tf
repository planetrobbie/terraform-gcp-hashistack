output "public_ip" {
  value = "Instances: ${element(google_compute_instance.vm.*.network_interface.0.access_config.0.assigned_nat_ip)}"
}
