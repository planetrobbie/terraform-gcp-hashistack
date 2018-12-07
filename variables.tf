variable "region" {
  description = "GCP region targeted"
  default = "europe-west1"
}

variable "region_zone" {
  description = "GCP zone targeted"
  default = "europe-west1-c"
}

variable "project_name" {
  description = "GCP project targeted"
}

#variable "account_file_path" {
#  description = "GCP credentials on disk"
#}

variable "image" {
  description = "GCP Image to use"
  default = "ubuntu-1804-lts"
}

variable "instance_type" {
  description = "GCP Machine Type to use"
  default = "n1-standard-1"
}

variable "ssh_user" {
  description = "instance SSH user"
  default = "sebastien"
}

variable "ssh_pub_key" {
  description = "SSH public key to authorize"
}

#### DNS

# Google Cloud DNS Zone
variable "gcp_dns_zone" {
  description = "Google Cloud zone name to create"  
}

# Google Cloud DNS Domain
variable "gcp_dns_domain" {
  description = "DNS Domain where to add entry"
}

# DNS TTL
variable "ttl" {
  description = "DNS ttl of entry"
  default = "300"
}

#### Google KMS

# Keyring

variable "gkms_location" {
  description = "Where the corresponding cryptographic keys are stored."
  default = "europe-west1"
}

variable "gkms_vault_key_ring" {
  description = "Keyring name which contain Vault masterkey for auto unseal"
  default = "ansible-vault"
}

variable "gkms_vault_key" {
  description = "name of the Vault Masterkey"
  default = "vault-key"
}

#### Google Firewalling

variable "external_source_ranges" {
  type = "list"
  description = "Which source range to allow inbound traffic to Consul API"
  default = ["0.0.0.0/0"]
}