# wordpress-vm

Multi-site WordPress platform for Proxmox using OpenTofu, Ansible, Docker Compose, and Caddy.

## Architecture

OpenTofu -> Proxmox VM
Ansible -> OS hardening, Docker, Caddy, deployment
Docker Compose -> WordPress + MariaDB stacks
Caddy -> HTTPS reverse proxy

Standard VM paths:

- `/opt/wordpress-platform` for shared Compose/Caddy/site platform config.
- `/opt/wordpress-platform/sites/<id>` for per-site Docker env files.
- `/opt/wordpress-runtime/<id>` for private per-site runtime files.
- `/opt/wordpress-deploy/<id>` for per-site deployment staging.

Do not use `/opt/wordpress` for new sites.

## Quick Start

1. Copy `opentofu/terraform.tfvars.example` to `opentofu/terraform.tfvars`.
2. Fill in local Proxmox, VM, and SSH key values. Do not commit `terraform.tfvars`.
3. Run `tofu init && tofu plan` from `opentofu/`.
4. Apply infrastructure.
5. Run Ansible playbook.
6. Open WordPress at `http://<VM_IP>/`.

## Documentation

- `docs/deployment-guide.md` has the end-to-end deployment flow.
- `docs/multi-site.md` covers running multiple independent WordPress sites on one VM.
- `docs/routing-options.md` covers direct DNS/IP routing and Cloudflare Tunnel.
- `docs/wsl-setup.md` covers WSL setup for Windows users.
- `docs/install-opentofu.md` covers OpenTofu installation.
- `docs/install-ansible.md` covers Ansible installation.
- `docs/wordpress-security.md` covers the baseline WordPress security defaults.
- `docs/ssh-guide.md` covers SSH key setup and VM access.

## Project Agents

Project-specific OpenCode subagents live in `.opencode/agent/`:

- `opentofu-proxmox` for Proxmox/OpenTofu infrastructure work.
- `ansible-wordpress` for VM configuration and app deployment work.
- `deployment-reviewer` for security and operations review.
