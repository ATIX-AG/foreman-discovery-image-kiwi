module "host" {
  source  = "git.atix.de/terraform/hcloud-host/hcloud"
  version = "~> 4.0"

  files_dir = "${path.root}/artifacts"

  dns_record_create          = false
  dns_wildcard_record_create = false

  host_name  = "fdi-build-${var.environment}"
  host_image = "fedora-37"

  ansible_playbook = "${path.module}/playbook.yaml"
  ansible_triggers = {
    time = timestamp()
  }

  firewall_create = false
}
