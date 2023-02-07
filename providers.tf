terraform {
  required_providers {
    aws    = { source = "hashicorp/aws" }
    hcloud = { source = "hetznercloud/hcloud" }
    local  = { source = "hashicorp/local" }
    random = { source = "hashicorp/random" }
    tls    = { source = "hashicorp/tls" }
  }

  #  backend "http" {}
}

provider "aws" {
  region     = "eu-central-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "hcloud" { token = var.hcloud_token }

provider "tls" {}
provider "local" {}
provider "random" {}
