provider "google" {
  region      = "${var.region}"
  project     = "${var.project_name}"
#  credentials = "${file(var.account_file_path)}"
}

# using cloud-init to install Python needed for Ansible
data "template_file" "userdata" {
    template = "${file("templates/userdata.tpl")}"
    vars {
    }
}

resource "google_compute_address" "consul-ip-addresses" {
  name = "consul-ip-${count.index}"
  count = 3
}

resource "google_compute_address" "vault-ip-addresses" {
  name = "vault-ip-${count.index}"
  count = 2
}

resource "google_compute_instance" "consul" {
  name         = "prod-consul-${count.index}"
  machine_type = "${var.instance_type}"
  zone         = "${var.region_zone}"
  allow_stopping_for_update = true

  tags = ["consul"]

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // static IP
      nat_ip = "${element(google_compute_address.consul-ip-addresses.*.address, count.index)}"
    }
  }

  metadata {
    sshKeys = "${var.ssh_user}:${var.ssh_pub_key}"
    user-data = "${data.template_file.userdata.rendered}"
  }

  count = 3
}

resource "google_compute_instance" "vault" {
  name         = "prod-vault-${count.index}"
  machine_type = "${var.instance_type}"
  zone         = "${var.region_zone}"
  allow_stopping_for_update = true

  tags = ["vault"]

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // static IP
      nat_ip = "${element(google_compute_address.vault-ip-addresses.*.address, count.index)}"
    }
  }

  metadata {
    sshKeys = "${var.ssh_user}:${var.ssh_pub_key}"
    user-data = "${data.template_file.userdata.rendered}"
  }

  # Label used by Vault GCP Auth GCE role to allow Instance Authentication.
  labels {
    auth = true
  }

  count = 2
}