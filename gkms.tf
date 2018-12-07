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
  account_id   = "sb-vault-kms"
  display_name = "sb-vault-kms Account"
}

resource "google_service_account_iam_binding" "kms-account-iam" {
  service_account_id = "sb-vault-kms"
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:sb-vault-kms@sb-vault.iam.gserviceaccount.com",
  ]
}