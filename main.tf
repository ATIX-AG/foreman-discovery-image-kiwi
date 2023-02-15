module "host" {
  source  = "git.atix.de/terraform/hcloud-host/hcloud"
  version = "~> 4.0"

  files_dir = "${path.root}/artifacts/builder"

  dns_record_create          = false
  dns_wildcard_record_create = false

  host_name   = "fdi-build-${var.environment}"
  host_image  = "fedora-37"
  host_labels = { role = "builder" }

  firewall_create = false
}

resource "local_sensitive_file" "pipeliner_ssh_private_key" {
  content         = var.pipeliner_ssh_private_key
  filename        = "${path.root}/artifacts/pipeliner_ssh.priv"
  file_permission = "0600"
}

module "inventory" {
  source  = "git.atix.de/terraform/ansible-inventory/local"
  version = "~> 3.0"

  from_yaml = [
    module.host.inventory,
    <<-EOF
---
all:
  hosts:
    factory:
      ansible_host: "factory.corp.atix.de"
      ansible_user: "pipeliner"
      ansible_ssh_private_key_file: "${abspath(local_sensitive_file.pipeliner_ssh_private_key.filename)}"
...
    EOF
  ]

  files_dir = "${path.root}/artifacts/"
  triggers  = { time = timestamp() }

  playbook = "${path.root}/playbook.yaml"
}
