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

You need to setup the following required Terraform variables in your workspace, for example:

      region: europe-west1
      region_zone: europe-west1-c
      project_name: <PROJECT_NAME>
      ssh_pub_key: <YOUR_SSH_PUBLIC_KEY>
      gcp_dns_zone: vault-prod
      gcp_dns_domain: prod.<DOMAIN_NAME>.

The SSH public key will be pushed to all instances to allow Ansible to connect to them.

Make sure you update the variable above according to your needs. You can also look inside `variable.tf` to see some other that you can update too.

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

    mkdir hashistack; cd hashistack
    vi hosts

    [consul_instances]
    c3.prod.<DOMAIN_NAME> consul_node_name=c1 consul_client_address="{{ consul_bind_address }}" consul_node_role=bootstrap  
    c2.prod.<DOMAIN_NAME> consul_node_name=c2 consul_client_address="{{ consul_bind_address }}" consul_node_role=server
    c1.prod.<DOMAIN_NAME> consul_node_name=c3 consul_client_address="{{ consul_bind_address }}" consul_node_role=server
    v1.prod.<DOMAIN_NAME> consul_node_name=cc1
    v2.prod.<DOMAIN_NAME> consul_node_name=cc2

    [vault_instances]
    v1.prod.<DOMAIN_NAME>
    v2.prod.<DOMAIN_NAME>

If you don't have any domain name that you can use to resolve your nodes, you'll have to replace all the FQDN above by their corresponding IP addresses that Terraform shared in its output, less fun.

### TLS Certificates

Create TLS Certificates using Lets Encrypt and DNS based challenge like this

    mkdir files; cd files
    certbot certonly --manual --preferred-challenges dns --config-dir . --work-dir . --logs-dir .

Update Google Cloud DNS to setup the requested challenge.

    gcloud dns record-sets transaction start -z=vault-prod
    gcloud dns record-sets transaction add -z=vault-prod \
      --name="_aacme-challenge.prod.<DOMAIN_NAME>." \
      --type=TXT \
      --ttl=300 "NhdbSiix2LdTJQri72UKp-_VDp28lm1LPzE92jjVRIc"
    gcloud dns record-sets transaction execute -z=vault-prod

In parallel check record availability:

    watch dig -t txt _acme-challenge.prod.<DOMAIN_NAME>

The value should correspond to the challenge. Continue the process only when that's the case, it could alternate which is normal due to propagation time, wait until it's stop alternating. It can take few minutes. Once you get your TLS certificates generated copy them in their expected location

    cp live/prod.<DOMAIN_NAME>/chain.pem ./ca.crt
    cp live/prod.<DOMAIN_NAME>/privkey.pem ./vault.key
    cp live/prod.<DOMAIN_NAME>/cert.pem ./vault.crt

Great !!! Almost there, stay with us ;)

### Google KMS Service Account

It's not a good practice to share our project owner key too widely, we need to give our Vault nodes a service account key that give them the right to interact with Google Cloud KMS nothing more, nothing less. Such an account has been created by Terraform earlier, we just need to download a key to inject in Vault configuration to enable Google KMS Auto-unseal.

Download a key like this:

    gcloud iam service-accounts keys create \
        ~/.config/gcloud/<PROJECT_NAME>-kms.json \
        --iam-account <PROJECT_NAME>-kms@<PROJECT_NAME>.iam.gserviceaccount.com

Protect this file as well as you can, it gives access to Google KMS !

We could have generated the key with Ansible but that expose it a bit more :/

### Ansible `site.yml`

The last step consist in telling Ansible what to do in `site.yml` like this
    
    cd hashistack
    vi site.yml

    - name: Configure Consul cluster
    hosts: consul_instances
    any_errors_fatal: true
    become: true
    become_user: root
    roles:
      - {role: ansible.consul}
    vars:
      ansible_ssh_user: <INSTANCE_USERNAME>
      consul_iface: ens4
      consul_install_remotely: true
      consul_version: 1.4.0
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
        ansible_ssh_user: <INSTANCE_USERNAME>
        vault_iface: ens4
      vault_install_remotely: true
      vault_version: 1.0.0
      vault_pkg: <ALTERNAME_PACKAGE_NAME>
      vault_checksum_file_url: <ALTERNATE_CHECKSUM_FILE>
      vault_zip_url: <ALTERNATE_DOWNLOAD_URL>
      vault_ui: true
      vault_tls_disable: false
      vault_tls_src_files: ./files
      validate_certs_during_api_reachable_check: false
      vault_gkms: true
      vault_gkms_project: '<PROJECT_NAME>'
      vault_gkms_credentials_src_file: '~/.config/gcloud/<PROJECT_NAME>-kms.json'
      vault_gkms_key_ring: 'ansible-vault'
      vault_gkms_region: 'europe-west1'

All the ALTERNAME variables are optional and useful if you want to deploy Enterprise binaries, you just have to specify the download URL, package name and checksum file.

### Ansible execution

Lastly to configure your Consul/Vault cluster, now execute the playbook with:

    ansible-playbook -i hosts site.yml

Obviously when everything looks good, it's a good practice to stop `sshd` on your cluster.

### Vault Initialize

Consul and Vault are now installed, the last manual step required is vault initialization:

    export https://v1.<YOUR_DOMAIN_NAME>:8200
    vault operator init    

### Check Vault Status

Now check Vault status it should be unsealed

    vault status
    Key                      Value
    ---                      -----
    Recovery Seal Type       shamir
    Initialized              true
    Sealed                   false
    Total Recovery Shares    5
    Threshold                3
    Version                  1.0.0
    Cluster Name             dc1
    Cluster ID               xx-xx-xx-xx-xx
    HA Enabled               true
    HA Cluster               https://xx.xx.xx.xx:8201
    HA Mode                  active
    Last WAL                 16

You now have a fully operational Consul/Vault Cluster congrat !!! If that's not the case read the next section.

### Troubleshooting

You can troubleshoot your deployment by running commands on all nodes like this

    ansible vault_instances -i hosts -a "systemctl status vault" -u sebastien --become

You can get detailed facts about a node

    ansible v1.prod.<DOMAIN_NAME> -i hosts -m setup -u sebastien

### Cluster Updgrades

Ansible can life cycle your cluster to upgrade Consul binaries. Add the following lines to your `site.yml` 

    consul_version: <CONSUL_VERSION>
    consul_install_upgrade: true

and run

    ansible-playbook -i hosts site.yml

To upgrade Vault binaries just bump up the `vault_version` in your `site.yml` file and run, this avoid re-running all the Consul related task:

    ansible-playbook -i hosts site.yml --start-at-task="Add Vault user"

Now restart the Vault cluster, it is manual due to the requirement for Unsealing if based on Shamir.

    ansible vault_instances -i hosts -a "systemctl restart vault" -u sebastien --become

## Google Cloud Load Balancing for Vault Cluster

We kept the resource to Load Balance the Vault Cluster outsite of this repo for the folowing reasons:

- Lets keep this one as simple and readable as possible, no modules !
- Not all the people would like to load balance the Vault Cluster using Google GSLB (layer-7) load balancing, because it opens up the secrets to them !

Unfortunately so far their Network Load Balancer (layer-4) can't leverage a HTTPS health check which is necessary for our cluster. A workaround consist of instantiating a NGINX service on each Vault node which will relay the healthcheck from HTTP to HTTPS but that adds a level of complexity and potential failure.

So for our demo environment I've decided to stick with [Google Cloud Global Load Balancer]() which also offer many advantages

- It is a software defined LB, no chokepoint !
- Can load balance easily to the DR Cluster in case of emergency
- Can load balance based on locality to address Performance replication nodes.

### Repository

So to provision this GSLB for your cluster, you can use the following repository:

    https://github.com/planetrobbie/terraform-vault-lb/

Version 1.0.10 of the Google Cloud module were [forked](https://github.com/planetrobbie/terraform-google-lb-http) to support https health check required for our Vault cluster.

### Required Variables

You just need to setup the following required variable, like in this example:

    project_name: <PROJECT_NAME>
    private_key_pem: <TLS_PRIV_KEY>
    cert_pem: <TLS_CERTIFICATE>
    vault_instances_names: ["prod-vault-0 ", "prod-vault-1"]. <- an HCL list !!
    gcp_dns_zone: vault-prod
    gcp_dns_domain: <YOUR_DOMAIN_NAME>

If you've created a wildcard TLS certificate for your domain, you can reuse it for your Load Balancer too.

Once you've provisioned your Load Balancer, after a while, few minutes, you should be able to access your cluster on the following URL

    https://vault.<YOUR_DOMAIN_NAME>

Thanks for reading this doc to the end ;) Good luck !