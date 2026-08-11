# WordPress Security Baseline

This project starts with a minimal security baseline for a single WordPress VM.

No WordPress deployment can be guaranteed to never get hacked. The goal is to reduce the default attack surface and make risky choices explicit before the site is exposed beyond a trusted LAN.

## Defaults Implemented

- MariaDB is only available inside the Docker Compose network.
- Caddy is the only container publishing host ports.
- Caddy adds baseline security headers.
- `/xmlrpc.php` is blocked by Caddy.
- `?author=` user enumeration requests are blocked by Caddy.
- `/readme.html`, `/license.txt`, and `/wp-config.php` requests are blocked by Caddy.
- `/wp-login.php` and `/wp-admin*` are restricted to private LAN IP ranges by default.
- WordPress theme/plugin file editing from the dashboard is disabled.
- WordPress core automatic updates are enabled.
- WordPress application passwords are disabled by the platform hardening must-use plugin.
- WordPress user REST endpoints are restricted by the platform hardening must-use plugin.

## Cloudflare/WAF Edge Protection

For public production sites, put Cloudflare or an equivalent WAF in front of Caddy. See `docs/cloudflare-waf.md`.

Recommended edge controls:

- Cloudflare proxied DNS or Cloudflare Tunnel.
- Managed WAF rules for WordPress and common web attacks.
- Bot protections and login-path rate limiting.
- Explicit protection for `/wp-login.php` and `/wp-admin/*`.
- Direct origin exposure avoided unless intentionally documented.

## Login Security Plugins

The playbook is configured to install and activate these plugins after WordPress core has been installed through the browser setup wizard:

```yaml
wordpress_security_plugins:
  - limit-login-attempts-reloaded
  - two-factor
```

`limit-login-attempts-reloaded` adds brute-force login throttling.

`two-factor` adds two-factor authentication support. After the plugin is active, each admin user still needs to configure 2FA in their WordPress profile.

If the playbook runs before WordPress is installed, plugin activation is skipped. Complete the WordPress setup wizard at `http://<VM_IP>/`, then rerun:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini site.yml
```

You can change the plugin list in `ansible/group_vars/all.yml`.

## Admin Access Restriction

The default variable is:

```yaml
wordpress_admin_private_only: true
```

With this enabled, login and admin URLs are reachable only from private IP ranges such as `192.168.0.0/16`, `10.0.0.0/8`, and `172.16.0.0/12`.

Public visitors can still access the normal site, but public internet clients cannot reach WordPress login paths.

If this site must be administered from the public internet, do not simply disable the restriction without adding another control such as VPN, IP allowlisting, or Caddy basic auth.

## HTTPS Admin

The default is:

```yaml
wordpress_force_ssl_admin: false
```

Keep this `false` while accessing WordPress by plain HTTP on a VM IP. Set it to `true` only after Caddy is serving the site over HTTPS with a real domain or trusted internal certificate.

## Required Operator Actions

- Configure Cloudflare/WAF protections before public launch.
- Use a strong WordPress admin password.
- Do not name the admin user `admin`.
- Enable 2FA for every administrator account after the `two-factor` plugin is active.
- Keep plugins and themes minimal.
- Delete unused themes and plugins.
- Avoid abandoned plugins.
- Back up MariaDB data and WordPress uploads before making major changes.
- Put the site behind HTTPS before entering credentials over an untrusted network.

## Recommended Next Hardening

- Add Caddy basic auth or VPN-only access for `/wp-login.php` and `/wp-admin*`.
- Add automated backups and restore tests.
- Add a WordPress security plugin only after deciding which features are actually needed.
- Add monitoring for container health and suspicious login activity.
- Set `wordpress_disallow_file_mods: true` after plugins/themes are fully managed by Ansible or another release workflow.
