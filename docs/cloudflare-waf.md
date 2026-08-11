# Cloudflare WAF Baseline

Use Cloudflare as the public edge control plane for production WordPress sites whenever possible. Caddy and WordPress hardening still apply on the VM, but Cloudflare should absorb common internet noise before it reaches the server.

## Recommended Controls

- Proxy public WordPress hostnames through Cloudflare orange-cloud DNS records.
- Enable Cloudflare managed WAF rules for WordPress and common web attacks.
- Enable bot protections appropriate for the site traffic profile.
- Add rate limiting for login and XML-RPC paths.
- Restrict `/wp-login.php` and `/wp-admin/*` by IP, VPN, Access policy, or another explicit admin access model.
- Keep TLS set to Full or Full Strict when Caddy terminates HTTPS on the VM.
- Do not expose the VM origin IP publicly when a Cloudflare Tunnel or proxied DNS model is intended.

## Suggested Rules

Use these as starting points, then tune for the site:

```text
Path equals /xmlrpc.php -> Block
Path starts with /wp-admin and not /wp-admin/admin-ajax.php -> Managed Challenge or IP allowlist
Path equals /wp-login.php -> Managed Challenge, rate limit, or IP allowlist
High request rate to WordPress login paths -> Rate limit
Known bots and verified good bots -> Allow
Suspicious automated traffic -> Managed Challenge
```

## Operator Checklist

- Confirm DNS points at Cloudflare, not directly at the VM, unless direct origin access is intentional.
- Confirm the hostname reaches the intended Caddy route.
- Confirm `/wp-login.php` and `/wp-admin/` are not publicly reachable without the intended protection.
- Confirm normal public pages, forms, images, and admin AJAX still work.
- Document any public admin access exception before launch.

Cloudflare configuration is intentionally documented rather than fully automated here because zone names, plans, WAF features, IP allowlists, and Access policies vary by account.
