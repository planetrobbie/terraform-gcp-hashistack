# Vault/Consul Cluster Deployment Automation with Terraform and Ansible.

- Infrastructure provisioned by Terraform Enterprise or Open Source [this code]
- Vault Auto-unseal enabled thru [Google Cloud KMS](https://learn.hashicorp.com/vault/operations/autounseal-gcp-kms)
- TLS Certificates generated using [Let's Encrypt](https://letsencrypt.org/)
- Cluster Configured using Brian Shumate Ansible Roles [available below]
  - https://github.com/brianshumate/ansible-consul/
  - https://github.com/brianshumate/ansible-vault/

## Google Cloud setup

If you aren't familiar with Google Cloud you can read our [Getting Starting guide](GCP.md) to setup the required GCP project, service account and get the necessary credentials.

## Terraform Enteprise (TFE) Workspace

Once your GCP environment is ready, reach [Terraform Enterprise UI](https://app.terraform.io) to create a Workspace linked to a fork of this repository in your organisation.

### Terraform Variables

You need to setup the following required Terraform variables in your workspace, as in this example

      region: europe-west1
      region_zone: europe-west1-c
      project_name: sb-vault
      ssh_pub_key: <YOUR_SSH_PUBLIC_KEY>
      gcp_dns_zone: vault-prod
      gcp_dns_domain: prod.yet.org.

Make sure you update the variable above according to your needs. You can also look inside `variable.tf` to see what other ones you can update.

### Terraform OSS

By the way if you provision your environment with Terraform OSS instead, make sure you uncomment the `account_file_path` variable in both this file and `main.tf`. And then setup all the variables values including your GCP credentials file location in `terraform.tfvars`.

### Terraform Environment Variable

For security concerns it's better to setup the Google Credentials in an Environment variable. So create a sensitive environment variable like this

      GOOGLE_CREDENTIALS: <JSON_KEY_ON_A_SINGLE_LINE>

Make sure you join all the lines of your JSON or Terraform Enterprise will complain, he doesn't accept newlines in environment variables.

## Terraform Plan

You're now ready to run a plan, click on `Queue Plan` in TFE UI. Or run `terraform plan` if you use OSS.

## Terraform Apply

Once the plan ends succesfully, you can click on `Confirm & Apply` in TFE UI. Or run `terraform apply`.

## Outputs

If you're lucky you should have an output giving you ip addresses of consul and vault nodes.

    Outputs:
    
    Vault IPs = [
        35.X33.6.X3,
        35.X95.59.X7
    ]
    consul IPs = [
        35.X89.235.X90,
        35.X41.245.X6,
        35.X41.130.X4
    ]

We deliberately refrain ourselves to use modules to keep everything in a single repository to make it more readable and to ease troubleshooting.

## Ansible workflow

### Ansible installation

Install Ansible on your control node:

    sudo easy_install pip
    sudo pip install ansible

### Roles configuration

Configure roles location in `~/.ansible.cfg`:

    mkdir ~/<PATH>/roles
    vi ~/.ansible.cfg
    [defaults]
    roles_path = ~/<PATH>/roles/

### Roles installation

Install Vault and Consul Ansible Roles:

    ansible-galaxy install brianshumate.consul
    ansible-galaxy install brianshumate.vault

### Ansible Inventory

Create an Inventory files with your nodes, based on the Terraform deployment, it should look like this:

    [consul_instances]
    c3.prod.yet.org consul_node_name=c1 consul_client_address="{{ consul_bind_address }}" consul_node_role=bootstrap  
    c2.prod.yet.org consul_node_name=c2 consul_client_address="{{ consul_bind_address }}" consul_node_role=server
    c1.prod.yet.org consul_node_name=c3 consul_client_address="{{ consul_bind_address }}" consul_node_role=server
    v1.prod.yet.org consul_node_name=cc1
    v2.prod.yet.org consul_node_name=cc2

    [vault_instances]
    v1.prod.yet.org
    v2.prod.yet.org

### TLS Certificates

Create TLS Certificates using Lets Encrypt and DNS based challenge like this

    mkdir files; cd files
    certbot certonly --manual --preferred-challenges dns --config-dir . --work-dir . --logs-dir .

Update Google Cloud DNS to setup the requested challenge.

    gcloud dns record-sets transaction start -z=vault-prod
    gcloud dns record-sets transaction add -z=vault-prod \
      --name="_aacme-challenge.prod.yet.org." \
      --type=TXT \
      --ttl=300 "NhdbSiix2LdTJQri72UKp-_VDp28lm1LPzE92jjVRIc"
    gcloud dns record-sets transaction execute -z=vault-prod

In parallel check record availability:

    watch dig -t txt _acme-challenge.prod.yet.org

The value should correspond to the challenge. Continue the process only when that's the case, it could alternate which is normal due to propagation time, wait until it's stop alternating. It can take few minutes. Once you get your TLS certificates generated copy them in their expected location

    cp live/prod.yet.org/chain.pem ./ca.crt
    cp live/prod.yet.org/privkey.pem ./vault.key
    cp live/prod.yet.org/cert.pem ./vault.crt

Great !!! Almost there, stay with us ;)

### Google KMS Service Account

It's not a good practice to share our project owner key too widely, we need to give our Vault nodes a service account key that give them the right to interact with Google Cloud KMS nothing more, nothing less. Such an account has been created by Terraform earlier, we just need to download a key to inject in Vault configuration to enable Google KMS Auto-unseal.

Download a key like this:

    gcloud iam service-accounts keys create \
        ~/.config/gcloud/sb-vault-kms.json \
        --iam-account sb-vault-kms@sb-vault.iam.gserviceaccount.com

Protect this file as well as you can, it gives access to Google KMS !

We could have generated the key with Ansible but that expose it a bit more :/

### Ansible `site.yml`

The last step consist in telling Ansible what to do in `site.yml` like this

    - name: Configure Consul cluster
      hosts: consul_instances
      any_errors_fatal: true
      become: true
      become_user: root
      roles:
        - {role: ansible.consul}
      vars:
        ansible_ssh_user: <USERNAME>
        consul_iface: ens4
        consul_install_remotely: true
        consul_pkg: <ALTERNAME_PACKAGE_NAME>
        consul_checksum_file_url: <ALTERNATE_CHECKSUM_FILE>
        consul_zip_url: <ALTERNATE_DOWNLOAD_URL>

    - name: Install Vault
      hosts: vault_instances
      any_errors_fatal: true
      become: true
      become_user: root
      roles:
        - {role: ansible.vault}
      vars:
        ansible_ssh_user: sebastien
        vault_iface: ens4
        vault_install_remotely: true
        vault_pkg: <ALTERNAME_PACKAGE_NAME>
        vault_checksum_file_url: <ALTERNATE_CHECKSUM_FILE>
        vault_zip_url: <ALTERNATE_DOWNLOAD_URL>
        vault_ui: true
        vault_tls_disable: false
        vault_tls_src_files: ./files
        validate_certs_during_api_reachable_check: false
        vault_gkms: true
        vault_gkms_project: 'sb-vault'
        vault_gkms_credentials_src_file: '~/.config/gcloud/sb-vault-kms.json'
        vault_gkms_key_ring: 'ansible-vault'
        vault_gkms_region: 'europe-west1'

All the ALTERNAME variables are optional and useful if you want to deploy Enterprise binaries, you just have to specify the download URL, package name and checksum file.

Lastly to configure your Consul/Vault cluster, now run:

    ansible-playbook -i hosts site.yml

Obviously when everything looks good, it's a good practice to stop sshd on your cluster.

You can troubleshoot your deployment by running commands on all nodes like this

    ansible vault_instances -i hosts -a "systemctl status vault" -u sebastien --become