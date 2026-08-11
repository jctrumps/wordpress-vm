# Architecture

This repository is a scaffold for deploying WordPress on Proxmox VE.

## Flow

1. OpenTofu provisions a VM from a Proxmox cloud-init template.
2. Ansible connects to the VM over SSH and installs/configures Docker.
3. Docker Compose runs Caddy plus one WordPress, WP-CLI, and MariaDB service set per site.
4. Caddy terminates HTTPS and reverse proxies traffic to WordPress.

## Standard VM Paths

Use these paths for all new sites:

| Path | Purpose |
| --- | --- |
| `/opt/wordpress-platform` | Shared platform files: rendered Compose, Caddyfile, site env files, platform scripts, and must-use plugins. |
| `/opt/wordpress-platform/sites/<id>` | Per-site Docker/platform environment files. |
| `/opt/wordpress-runtime/<id>` | Private per-site runtime files, logs, token caches, secrets-adjacent files, and compatibility mounts. |
| `/opt/wordpress-deploy/<id>` | Per-site Git/rsync deployment staging. |

Do not use `/opt/wordpress` for new sites. If an older site still has `/opt/wordpress/runtime/<id>`, treat it as a legacy runtime path and migrate it intentionally during a maintenance window.

## Current State

- `opentofu/` contains a single VM resource scaffold using the `bpg/proxmox` provider.
- `ansible/` installs Docker, creates standard platform/runtime/deploy directories, renders Compose and Caddy files, and starts the selected WordPress sites.
- `compose/` contains Caddy and multi-site WordPress Compose templates.
- `.opencode/agent/` contains project-specific agents for future infrastructure and deployment work.
