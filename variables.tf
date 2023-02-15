variable "hcloud_token" {
  type      = string
  sensitive = true
}

variable "aws_access_key" {
  type = string
}

variable "aws_secret_key" {
  type      = string
  sensitive = true
}

variable "environment" {
  type = string
}

variable "pipeliner_ssh_private_key" {
  type      = string
  sensitive = true
}
