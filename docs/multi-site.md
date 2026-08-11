# Multiple WordPress Sites

This project can run multiple independent WordPress sites on the same VM.

Each site gets its own:

- WordPress container
- MariaDB container
- WordPress volume
- MariaDB volume
- generated database credentials
- Caddy route
- `/opt/wordpress-platform/sites/<id>` platform env/config directory
- `/opt/wordpress-runtime/<id>` private runtime directory
- `/opt/wordpress-deploy/<id>` Git/deploy staging directory

This is not WordPress Multisite. It is multiple separate WordPress installs sharing one VM and one Caddy container.

## Add A Site

Edit `ansible/group_vars/all.yml` and add entries under `wordpress_sites`:

```yaml
wordpress_sites:
  - id: smoke_test
    server_name: ":80"
    db_name: smoke_test
    db_user: smoke_test

  - id: blog
    server_name: "blog.example.com"
    url: "https://blog.example.com"
    db_name: blog
    db_user: blog

  - id: store
    server_name: "store.example.com"
    url: "https://store.example.com"
    db_name: store
    db_user: store
```

The `id` must use only lowercase letters, numbers, and underscores. It is used in Docker service names, volume names, `/opt/wordpress-platform/sites/<id>/`, `/opt/wordpress-runtime/<id>/`, and `/opt/wordpress-deploy/<id>/`.

Do not use `/opt/wordpress` for new sites. If an older site still has `/opt/wordpress/runtime/<id>`, treat it as a legacy runtime path and migrate it intentionally during a maintenance window.

The `server_name` is the hostname Caddy matches. The `url` is the public URL WordPress should generate for links, images, CSS, JavaScript, and login redirects. For Cloudflare Tunnel, use the public `https://...` URL.

## Hostnames

Multiple sites need different hostnames because they all share ports `80` and `443` on the same VM.

Choose either direct routing or Cloudflare Tunnel for those hostnames. See `docs/routing-options.md`.

For real DNS, point each hostname at the VM IP:

```text
blog.example.com  -> <VM_IP>
store.example.com -> <VM_IP>
```

For local testing on Windows, add entries to `C:\Windows\System32\drivers\etc\hosts` as Administrator:

```text
<VM_IP> blog.example.test
<VM_IP> store.example.test
```

Then use those names as `server_name` values.

The default `server_name: ":80"` is a catch-all HTTP site. Use it for a single-site VM. For multiple sites, prefer explicit hostnames.

## Deploy All Sites

From WSL in `ansible/`:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini site.yml
```

This deploys every site listed in `wordpress_sites`.

## Deploy One Site

Pass the site ID:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini site.yml -e wordpress_site=blog
```

This prepares and starts only the selected site's WordPress and MariaDB services, plus Caddy. The Compose and Caddy configs are still rendered from the full `wordpress_sites` list so existing site routes are preserved.

## First-Time Setup Per Site

After deploying a new site, open its URL and complete the WordPress browser setup wizard:

```text
http://blog.example.com/
```

Then rerun the playbook for that site so Ansible can activate the configured security plugins:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini site.yml -e wordpress_site=blog
```

If WordPress was first configured through `http://<VM_IP>/`, some resources may point to the private IP. Set `url` for the site and rerun the playbook. Ansible updates `home` and `siteurl`, then runs `wp search-replace` for the old URL.

To verify the saved URLs for one site:

```bash
ssh -i ~/.ssh/wordpress_01_ed25519 ubuntu@<VM_IP>
cd /opt/wordpress-platform
sudo docker compose run --rm blog_wpcli wp option get home
sudo docker compose run --rm blog_wpcli wp option get siteurl
sudo docker compose run --rm blog_wpcli wp search-replace "http://<VM_IP>" "https://blog.example.com" --dry-run --skip-columns=guid --all-tables
```

If the dry run reports replacements, rerun the Ansible playbook for that site.

## Check Containers

From WSL in `ansible/`:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible -i inventory.ini wordpress -a "docker ps"
```

Or SSH to the VM:

```bash
ssh -i ~/.ssh/wordpress_01_ed25519 ubuntu@<VM_IP>
cd /opt/wordpress-platform
sudo docker compose ps
```

Service names follow this pattern:

```text
<id>_wordpress
<id>_db
<id>_wpcli
```

Example for `id: blog`:

```text
blog_wordpress
blog_db
blog_wpcli
```

## Backups

Back up each site's database and WordPress files separately. Each site has separate Docker volumes:

```text
<id>_wordpress_data
<id>_db_data
```

Backup, restore, source-file scanning, database import, and URL replacement are handled by site migration projects derived from `wordpress-migration-template`. Do not treat a production site as protected until its migration/onboarding project has a tested backup and restore workflow.
