resource "google_compute_firewall" "allow-inbound-vault-api" {
  name    = "allow-inbound-vault-api"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["8200"]
  }
 
  target_tags = ["vault"]
}

resource "google_compute_firewall" "allow-inbound-consul-api" {
  name    = "allow-inbound-consul-api-dns"
  description = "allow API and DNS traffic to Consul nodes"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["8500", "53"]
  }

  allow {
    protocol = "udp"
    ports = ["53"]
  }

  target_tags = ["consul"]
  source_ranges = "${var.external_source_ranges}"
}

resource "google_compute_firewall" "allow-consul-2-consul" {
  name    = "allow-consul-2-consul"
  description = "allow internal consul traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["8300", "8500"]
  }

  allow {
    protocol = "udp"
    ports = ["8301", "8302"]
  }

  source_tags = ["consul"]
  target_tags = ["consul"]
}

resource "google_compute_firewall" "allow-vault-2-vault" {
  name    = "allow-vault-2-vault"
  description = "allow internal vault traffic"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["8201"]
  }

  source_tags = ["vault"]
  target_tags = ["vault"]
}

resource "google_compute_firewall" "allow-inbound-consul-dns" {
  name    = "allow-inbound-consul-dns"
  description = "allow DNS traffic to Consul nodes"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["8600"]
  }

  allow {
    protocol = "udp"
    ports = ["8600"]
  }

  target_tags = ["consul"]
}