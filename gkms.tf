resource "google_kms_key_ring" "vault_keyring" {
  name     = "${var.gkms_vault_key_ring}"
  project  = "${var.project_name}"
  location = "${var.gkms_location}"
}

resource "google_kms_crypto_key" "vault_key" {
  name            = "${var.gkms_vault_key}"
  key_ring        = "${google_kms_key_ring.vault_keyring.self_link}"
}

resource "google_service_account" "kms_access" {
  account_id   = "${var.project_name}-kms"
  display_name = "${var.project_name} Account"
}

resource "google_kms_key_ring_iam_binding" "vault_iam_kms_binding" {
   key_ring_id = "${var.project_name}/${var.gkms_location}/${var.gkms_vault_key_ring}"
   role = "roles/owner"

   members = [
     "serviceAccount:${google_service_account.kms_access.email}",
   ]
}