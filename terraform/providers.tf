terraform {
  required_version = "~> 1.8"

  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "~> 2.9.14"
    }
  }
}

variable "proxmox_api_url" {
  type = string
  validation {
    condition     = can(regex("^https?://.*(:[0-9]+)?/api2/json/?$", var.proxmox_api_url))
    error_message = "The url must be something like 'https://url:8006/api2/json'."
  }
}
variable "proxmox_api_token_id" {
  type      = string
  sensitive = true
  validation {
    condition     = can(regex("^.*@.*!.*$", var.proxmox_api_token_id))
    error_message = "The token_id must be something like 'user@pam!name'."
  }
}
variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-5][0-9a-fA-F]{3}-[089abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", var.proxmox_api_token_secret))
    error_message = "The token_secret must be a valid uuid4 token."
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret

  pm_tls_insecure = true
}

# vim: sw=2
