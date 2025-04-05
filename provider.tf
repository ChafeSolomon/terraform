terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.72.0"
    }
  }
}

provider "proxmox" {
  endpoint = "https://proxmox.thesolomonsnc.com:8006/api2/json"

  # TODO: use terraform variable or remove the line, and use PROXMOX_VE_USERNAME environment variable
  username = "root@pam"
  # TODO: use terraform variable or remove the line, and use PROXMOX_VE_PASSWORD environment variable
  password = "29231213"

  # because self-signed TLS certificate is in use
  insecure = true
  # uncomment (unless on Windows...)
  # tmp_dir  = "/var/tmp"

  ssh {
    agent = true
    # TODO: uncomment and configure if using api_token instead of password
    # username = "root"
  }
}


