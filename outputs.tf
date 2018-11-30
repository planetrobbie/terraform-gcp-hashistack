output "consul IPs" {
  value = ["${google_compute_instance.vm.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

output "Vault IPs" {
  value = ["${google_compute_instance.vault.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}
