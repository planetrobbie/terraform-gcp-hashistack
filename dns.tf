resource "google_dns_managed_zone" "dns_zone" {
  name     = "${var.gcp_dns_zone}"
  dns_name = "${var.gcp_dns_domain}"
}

resource "google_dns_record_set" "v1" {
  name = "v1.${google_dns_managed_zone.dns_zone.dns_name}"
  type = "A"
  ttl  = "${var.ttl}"

  managed_zone = "${google_dns_managed_zone.dns_zone.name}"

  rrdatas = ["${google_compute_instance.vault.0.network_interface.0.access_config.0.assigned_nat_ip}"]
}
