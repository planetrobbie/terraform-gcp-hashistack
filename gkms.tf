resource "google_kms_key_ring" "vault_keyring" {
  name     = "${var.gkms_vault_key_ring}"
  project  = "${var.project_name}"
  location = "${var.gkms_location}"
}

resource "google_kms_crypto_key" "vault_key" {
  name            = "${var.gkms_vault_key}"
  key_ring        = "${google_kms_key_ring.vault_keyring.self_link}"

  lifecycle {
    prevent_destroy = true
  }
}