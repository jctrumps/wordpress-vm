# Deployment Guide

This guide covers the initial deployment flow for the WordPress platform on Proxmox VE.

Current repo state: OpenTofu provisions the VM, and Ansible installs Docker, renders the shared WordPress/Caddy Compose stack, creates standard platform/runtime/deploy directories, and starts the configured WordPress sites.

## 1. Prepare The Workstation

If you are deploying from Windows, set up WSL first:

- See `docs/wsl-setup.md`.

Install OpenTofu:

- See `docs/install-opentofu.md`.

Install Ansible:

- See `docs/install-ansible.md`.

Confirm both tools are available:

```bash
tofu version
ansible-playbook --version
```

## 2. Prepare Proxmox

Before running OpenTofu, Proxmox needs these items:

- A Proxmox VE API endpoint, usually `https://<PROXMOX_HOST>:8006/api2/json`.
- A Proxmox API token with permissions to clone and manage the target VM.
- A target node name, for example `pve`.
- A cloud-init VM template ID, for example `9000`.
- A datastore for the VM disk and cloud-init disk, for example `local-lvm`.
- A network bridge, usually `vmbr0`.

The cloud-init template should already have:

- Debian or Ubuntu installed.
- Cloud-init enabled.
- SSH server available.
- A default user compatible with `vm_username`.
- `qemu-guest-agent` installed and running only if you set `vm_qemu_agent_enabled = true`.

Leave `vm_qemu_agent_enabled = false` if you are unsure. Enabling the Proxmox guest agent when the VM does not run it can cause long OpenTofu waits and failed shutdown operations.

## 3. Choose Traffic Routing

Before exposing WordPress, choose how traffic will reach the VM:

- Direct DNS/IP routing to the VM on ports `80` and `443`.
- Cloudflare Tunnel through `cloudflared` without inbound port forwarding.

See `docs/routing-options.md` for both paths.

For public WordPress sites, also plan Cloudflare/WAF protections before launch. See `docs/cloudflare-waf.md` and `docs/wordpress-security.md`.

For a single LAN test site, the default `server_name: ":80"` works with `http://<VM_IP>/`.

For a clean VM smoke test, use a neutral site entry like this in `ansible/group_vars/all.yml`:

```yaml
wordpress_sites:
  - id: smoke_test
    server_name: ":80"
    db_name: smoke_test
    db_user: smoke_test
```

This creates containers named `smoke_test_wordpress`, `smoke_test_db`, and `smoke_test_wpcli`. After that proves the platform works, use a migration project derived from `wordpress-migration-template` to add and migrate real sites.

For multiple sites or public domains, update `wordpress_sites[*].server_name` in `ansible/group_vars/all.yml` before running Ansible.

Also set each site's public `url`. For Cloudflare Tunnel this should be the public HTTPS URL:

```yaml
wordpress_sites:
  - id: blog
    server_name: "blog.example.com"
    url: "https://blog.example.com"
    db_name: blog
    db_user: blog
```

This prevents WordPress from saving or generating resource URLs that point to the VM private IP.

## 4. Prepare SSH

Create or reuse a dedicated SSH key for this VM:

```powershell
ssh-keygen -t ed25519 -f "$HOME\.ssh\wordpress_01_ed25519" -C "wordpress-01"
```

Use the public key path in OpenTofu:

```hcl
vm_ssh_public_key_path = "C:/Users/<YOUR_NAME>/.ssh/wordpress_01_ed25519.pub"
```

For more SSH details, see `docs/ssh-guide.md`.

## 5. Configure OpenTofu Variables

Copy the example variable file:

```bash
cd opentofu
cp terraform.tfvars.example terraform.tfvars
```

Edit `opentofu/terraform.tfvars` and replace the placeholders:

```hcl
proxmox_endpoint  = "https://proxmox.example.com:8006/api2/json"
proxmox_api_token = "root@pam!opentofu=REPLACE_WITH_TOKEN_SECRET"
proxmox_node      = "pve"
template_vm_id    = 9000
vm_name           = "wordpress-01"
vm_id             = 130
```

Do not commit `terraform.tfvars`. It contains local settings and secrets.

## 6. Initialize And Validate OpenTofu

From `opentofu/`:

```bash
tofu fmt
tofu init
tofu validate
```

If `tofu init` fails, check:

- Network access to the provider registry.
- The `bpg/proxmox` provider version constraint in `main.tf`.
- Local firewall or proxy settings.

## 7. Review The Infrastructure Plan

From `opentofu/`:

```bash
tofu plan -out wordpress.tfplan
```

Review the plan before applying. Confirm it will create the intended VM ID on the intended Proxmox node.

## 8. Apply Infrastructure

From `opentofu/`:

```bash
tofu apply wordpress.tfplan
```

After apply, check the Proxmox UI for the new VM.

If using DHCP, find the VM IP from your router, DHCP server, Proxmox neighbor table, or QEMU guest agent if enabled. See `docs/ssh-guide.md` for examples.

## 9. Create An Ansible Inventory

The repo ignores `ansible/inventory.ini` because it is environment-specific. Create it locally after you know the VM IP:

```bash
cp inventory.ini.example inventory.ini
```

Then edit `inventory.ini`:

```ini
[wordpress]
wordpress-01 ansible_host=<VM_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/wordpress_01_ed25519
```

Use the same `ansible_user` as `vm_username` from `opentofu/terraform.tfvars`.

If you are working from Windows PowerShell or CMD and then entering WSL from the project directory, the workflow looks like this:

```powershell
cd C:/web-projects/wordpress
cd ansible
wsl
```

After `wsl` starts, confirm you are in the mounted Windows project path:

```bash
pwd
```

Expected path:

```text
/mnt/c/web-projects/wordpress/ansible
```

Create or edit the inventory from that WSL shell:

```bash
nano inventory.ini
```

Example `inventory.ini`:

```ini
[wordpress]
wordpress-01 ansible_host=<VM_IP> ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/wordpress_01_ed25519
```

Confirm Ansible can parse the inventory:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-inventory -i inventory.ini --list
```

The output should include a `wordpress` group and the `wordpress-01` host.

When running Ansible from WSL under `/mnt/c/...`, always pass `ANSIBLE_CONFIG` and `-i inventory.ini` explicitly. Windows-mounted directories can appear world-writable to Linux, which can make Ansible ignore `ansible.cfg` during automatic config discovery.

If your SSH key is passphrase-protected, or if SSH authentication fails, start `ssh-agent` and load the key inside WSL:

```bash
mkdir -p ~/.ssh
cp /mnt/c/Users/<YOUR_NAME>/.ssh/wordpress_01_ed25519 ~/.ssh/wordpress_01_ed25519
chmod 700 ~/.ssh
chmod 600 ~/.ssh/wordpress_01_ed25519

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/wordpress_01_ed25519
```

## 10. Test Ansible Connectivity

From `ansible/`:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible -i inventory.ini wordpress -m ping
```

If this fails, check:

- The VM IP address.
- The SSH private key path and permissions.
- The cloud-init username.
- Whether the public key was injected into the VM.

If you see this warning:

```text
[WARNING]: provided hosts list is empty, only localhost is available. Note that the implicit localhost does not match 'all'
[WARNING]: Could not match supplied host pattern, ignoring: wordpress
```

Ansible did not load a `wordpress` host group from `inventory.ini`. Check these items from the WSL shell:

```bash
pwd
ls -la inventory.ini
cat inventory.ini
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-inventory -i inventory.ini --list
```

The inventory file must be in the current directory, must not be empty, and must contain a `[wordpress]` group. If you entered WSL from `C:\web-projects\wordpress\ansible`, the WSL path should be `/mnt/c/web-projects/wordpress/ansible`.

If `ls -la inventory.ini` shows size `0`, the file exists but has no hosts. Recreate it from the example and replace `<VM_IP>` with the real VM IP:

```bash
cp inventory.ini.example inventory.ini
nano inventory.ini
cat inventory.ini
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-inventory -i inventory.ini --list
```

If `ssh-add ~/.ssh/wordpress_01_ed25519` fails with `No such file or directory`, WSL does not have the private key yet. Copy it from Windows if it exists there:

```bash
eval "$(ssh-agent -s)"
mkdir -p ~/.ssh
cp /mnt/c/Users/<YOUR_NAME>/.ssh/wordpress_01_ed25519 ~/.ssh/wordpress_01_ed25519
chmod 700 ~/.ssh
chmod 600 ~/.ssh/wordpress_01_ed25519
ssh-add ~/.ssh/wordpress_01_ed25519
```

If the Windows key file does not exist, create a key and update `opentofu/terraform.tfvars` so `vm_ssh_public_key_path` points to the matching `.pub` file before creating or recreating the VM.

If Ansible prints a warning like this:

```text
Ansible is being run in a world writable directory, ignoring it as an ansible.cfg source.
```

Keep using the explicit `ANSIBLE_CONFIG="$PWD/ansible.cfg"` prefix. If Ansible still behaves inconsistently, copy or clone the repo inside the WSL filesystem, for example `~/projects/wordpress`, and run Ansible from there.

## 11. Run The Playbook

From `ansible/`:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini site.yml
```

The playbook installs Docker, creates `/opt/wordpress-platform`, creates standard per-site companion directories under `/opt/wordpress-runtime/<id>` and `/opt/wordpress-deploy/<id>`, generates database passwords on the VM, renders the Compose/Caddy files, and starts the stack.

For multiple sites or deploying one site at a time, see `docs/multi-site.md`.

After it completes, open WordPress in a browser:

```text
http://<VM_IP>/
```

Use the same IP from `inventory.ini`. For example, if `ansible_host=192.168.1.50`, open:

```text
http://192.168.1.50/
```

The first load can take a minute while MariaDB initializes and WordPress finishes starting.

By default, WordPress login and admin paths are restricted to private LAN IP ranges. This means `/wp-login.php` and `/wp-admin/` should work from your LAN, but should return `403` from public internet clients. See `docs/wordpress-security.md` for the baseline security settings.

After completing the WordPress browser setup wizard, rerun the playbook once. The second run activates the configured login security plugins because WordPress core is installed at that point:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini site.yml
```

To check containers from Ansible:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible -i inventory.ini wordpress -a "docker ps"
```

To check logs directly on the VM:

```bash
ssh -i ~/.ssh/wordpress_01_ed25519 ubuntu@<VM_IP>
cd /opt/wordpress-platform
sudo docker compose ps
sudo docker compose logs -f
```

## 12. Expected Next Implementation Work

The deployment can create one or more independent WordPress sites. Remaining production hardening work includes:

- Ansible Vault or another secret workflow for externally managed credentials.
- Runtime/deploy integration for site-specific application dependencies as those needs are identified.

Backup, restore, source-file scanning, database import, and URL replacement are handled by site migration projects derived from `wordpress-migration-template`.

## 13. Cleanup

To destroy the VM, review the plan first:

```bash
cd opentofu
tofu plan -destroy
```

Then destroy only when you are sure:

```bash
tofu destroy
```

Destruction removes the VM managed by OpenTofu. Back up any WordPress uploads and database data before destroying a deployed application VM.
