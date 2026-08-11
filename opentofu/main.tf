terraform {
  required_version = ">= 1.8.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.70"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
}

resource "proxmox_virtual_environment_vm" "wordpress" {
  name      = var.vm_name
  node_name = var.proxmox_node
  vm_id     = var.vm_id
  tags      = var.vm_tags

  clone {
    vm_id        = var.template_vm_id
    datastore_id = var.vm_datastore
    full         = true
  }

  agent {
    enabled = var.vm_qemu_agent_enabled
  }

  stop_on_destroy = true

  cpu {
    cores = var.vm_cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.vm_memory_mb
  }

  disk {
    datastore_id = var.vm_datastore
    interface    = "scsi0"
    size         = var.vm_disk_size_gb
  }

  network_device {
    bridge = var.vm_network_bridge
  }

  operating_system {
    type = "l26"
  }

  initialization {
    datastore_id = var.vm_datastore

    dns {
      domain  = var.vm_dns_domain
      servers = var.vm_dns_servers
    }

    ip_config {
      ipv4 {
        address = var.vm_ipv4_address
        gateway = var.vm_ipv4_gateway
      }
    }

    user_account {
      username = var.vm_username
      keys     = [trimspace(file(var.vm_ssh_public_key_path))]
    }
  }
}

output "wordpress_vm_id" {
  value = proxmox_virtual_environment_vm.wordpress.vm_id
}

output "wordpress_vm_name" {
  value = proxmox_virtual_environment_vm.wordpress.name
}
