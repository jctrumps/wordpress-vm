variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint, for example https://pve.example.com:8006/api2/json."
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API token in the form user@realm!token-id=secret."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow insecure TLS when Proxmox uses a self-signed certificate."
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Proxmox node name that will host the WordPress VM."
  type        = string
}

variable "template_vm_id" {
  description = "VM ID of the cloud-init template to clone."
  type        = number
}

variable "vm_name" {
  description = "Name of the WordPress VM."
  type        = string
  default     = "wordpress-01"
}

variable "vm_id" {
  description = "Proxmox VM ID to assign to the WordPress VM."
  type        = number
  default     = 130
}

variable "vm_tags" {
  description = "Tags applied to the WordPress VM in Proxmox."
  type        = list(string)
  default     = ["wordpress", "docker", "opentofu"]
}

variable "vm_cpu_cores" {
  description = "Number of vCPU cores."
  type        = number
  default     = 2
}

variable "vm_memory_mb" {
  description = "Dedicated memory in MB."
  type        = number
  default     = 4096
}

variable "vm_disk_size_gb" {
  description = "Root disk size in GB."
  type        = number
  default     = 40
}

variable "vm_datastore" {
  description = "Proxmox datastore for VM disks and cloud-init media."
  type        = string
  default     = "local-lvm"
}

variable "vm_network_bridge" {
  description = "Proxmox network bridge for the VM NIC."
  type        = string
  default     = "vmbr0"
}

variable "vm_username" {
  description = "Cloud-init user for SSH and Ansible."
  type        = string
  default     = "ubuntu"
}

variable "vm_qemu_agent_enabled" {
  description = "Enable only when the template already installs and starts qemu-guest-agent."
  type        = bool
  default     = false
}

variable "vm_ssh_public_key_path" {
  description = "Path to the public SSH key injected by cloud-init."
  type        = string
}

variable "vm_ipv4_address" {
  description = "Static IPv4 CIDR for the VM, or dhcp."
  type        = string
  default     = "dhcp"
}

variable "vm_ipv4_gateway" {
  description = "IPv4 gateway for static addressing. Leave null when using DHCP."
  type        = string
  default     = null
}

variable "vm_dns_domain" {
  description = "DNS search domain for the VM."
  type        = string
  default     = null
}

variable "vm_dns_servers" {
  description = "DNS servers for the VM."
  type        = list(string)
  default     = []
}
