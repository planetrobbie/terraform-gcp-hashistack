Vault/Consul Cluster:

- Infrastructure provisioned by Terraform in this repository
- Configured by Brian Shumate Ansible Roles

For Consul, Vault Ansible roles check:

- https://github.com/brianshumate/ansible-consul/
- https://github.com/brianshumate/ansible-vault/

To create a cluster you first have to create an Inventory files with your nodes, for example:

    [consul_instances]
    c3.demo.yet.org consul_node_name=c1 consul_client_address="{{ consul_bind_address }}" consul_node_role=bootstrap  
    c2.demo.yet.org consul_node_name=c2 consul_client_address="{{ consul_bind_address }}" consul_node_role=server
    c1.demo.yet.org consul_node_name=c3 consul_client_address="{{ consul_bind_address }}" consul_node_role=server
    v1.demo.yet.org consul_node_name=cc1
    v2.demo.yet.org consul_node_name=cc2

    [vault_instances]
    v1.demo.yet.org
    v2.demo.yet.org

And tell Ansible what to do in `site.yml` like this

    - name: Configure Consul cluster
      hosts: consul_instances
      any_errors_fatal: true
      become: true
      become_user: root
      roles:
        - {role: brianshumate.consul}
      vars:
        ansible_ssh_user: sebastien
        consul_iface: ens4
        consul_install_remotely: true
    
    - name: Install Vault
      hosts: vault_instances
      any_errors_fatal: true
      become: true
      become_user: root
      roles:
        - {role: brianshumate.vault}
      vars:
        ansible_ssh_user: <USERNAME>
        vault_iface: ens4
        vault_install_remotely: true
        vault_ui: true
        vault_tls_disable: false
        vault_tls_src_files: <PATH_OF_YOUR_CERT_FILES>
        validate_certs_during_api_reachable_check: false

Once the infrastructrure is provisioned with Terraform, lastly to configure your cluster, just run:

    ansible-playbook -i hosts site.yml
