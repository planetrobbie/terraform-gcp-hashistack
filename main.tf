provider "google" {
  region      = "${var.region}"
  project     = "${var.project_name}"
#  credentials = "${file(var.account_file_path)}"
}

data "template_file" "userdata" {
    template = "${file("templates/userdata.tpl")}"
    vars {
    }
}

resource "google_compute_instance" "vm" {
  name         = "ansible-consul-${count.index}"
  machine_type = "${var.instance_type}"
  zone         = "${var.region_zone}"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "${var.image}"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  metadata {
    sshKeys = "${var.ssh_user}:${var.ssh_pub_key}"
    user-data = "${data.template_file.userdata.rendered}"
  }

  count = 3
}
