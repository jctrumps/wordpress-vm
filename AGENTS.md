# AGENTS

Project conventions and automation notes for the WordPress platform repo.

## Project Goal

Deploy a WordPress platform on Proxmox VE:

- OpenTofu provisions a Debian/Ubuntu VM from a cloud-init template.
- Ansible configures the VM, installs Docker, and deploys Compose stacks.
- Docker Compose runs Caddy, WordPress, and MariaDB containers.

## Working Rules

- Do not commit secrets. Keep real Proxmox tokens, passwords, SSH keys, and site credentials out of tracked files.
- Use `opentofu/terraform.tfvars.example` as the template for local `opentofu/terraform.tfvars`.
- Prefer small, reviewable changes. This repo is still scaffolded, so avoid inventing production policy without documenting assumptions.
- Validate OpenTofu changes with `tofu fmt` and `tofu validate` from `opentofu/` when `tofu` is available.
- Validate Ansible changes with `ansible-playbook --syntax-check site.yml` from `ansible/` when Ansible is available.

## Expected Layout

- `opentofu/` contains Proxmox infrastructure code.
- `ansible/` contains VM configuration and application deployment playbooks.
- `compose/` contains Docker Compose and Caddy templates.
- `docs/` contains operator docs and architecture notes.
- `.opencode/agent/` contains project-specific OpenCode subagents.
