# Routing Options

This VM can serve WordPress traffic in two common ways:

- Direct routing by domain name or IP address.
- Cloudflare Tunnel through `cloudflared`.

Choose one path before exposing a site outside your LAN.

## Option 1: Direct DNS Or IP Routing

Use direct routing when you want normal internet traffic to connect to the VM on ports `80` and `443`.

### Requirements

- A domain name for each WordPress site, or LAN-only hostnames for local testing.
- DNS records pointing each site hostname to your public IP or LAN VM IP.
- Router/firewall port forwarding if exposing from a home network.
- Ports `80/tcp` and `443/tcp` forwarded to the WordPress VM.
- Caddy configured with the same hostnames in `wordpress_sites[*].server_name`.

### Public DNS Example

For a public deployment:

```text
blog.example.com  A     <PUBLIC_IP>
store.example.com A     <PUBLIC_IP>
```

Then forward on your router/firewall:

```text
WAN 80/tcp  -> <VM_IP>:80
WAN 443/tcp -> <VM_IP>:443
```

Set matching site names in `ansible/group_vars/all.yml`:

```yaml
wordpress_sites:
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

For Cloudflare Tunnel, set `url` to the public HTTPS URL even though Cloudflare connects to Caddy over HTTP internally. This prevents WordPress from generating image, CSS, JavaScript, and login URLs with the VM private IP.

Deploy:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini site.yml
```

### LAN Hosts File Example

For local testing without public DNS, add entries to `C:\Windows\System32\drivers\etc\hosts` as Administrator:

```text
<VM_IP> blog.example.test
<VM_IP> store.example.test
```

Then use matching `server_name` values:

```yaml
wordpress_sites:
  - id: blog
    server_name: "blog.example.test"
    db_name: blog
    db_user: blog
```

### Security Notes

- Direct public routing exposes Caddy and WordPress to the internet.
- Keep `wordpress_admin_private_only: true` unless you have a VPN or another admin access control.
- Use HTTPS before entering credentials over untrusted networks.
- Confirm backups exist before public exposure.

## Option 2: Cloudflare Tunnel

Use Cloudflare Tunnel when you do not want to open inbound router/firewall ports. In this model, `cloudflared` creates an outbound tunnel to Cloudflare, and Cloudflare routes selected hostnames to services on the VM.

### Requirements

- Domain managed in Cloudflare DNS.
- Cloudflare Zero Trust account.
- `cloudflared` installed on the WordPress VM or another always-on machine that can reach the VM.
- A tunnel route for each WordPress hostname.

### Recommended Origin URL

Point Cloudflare Tunnel at Caddy on the VM:

```text
http://127.0.0.1:80
```

If `cloudflared` runs on another machine, point it at:

```text
http://<VM_IP>:80
```

Caddy still needs `server_name` entries that match the public hostnames so it can route to the right WordPress container.

### Cloudflare Dashboard Setup

This workflow assumes `cloudflared` runs on the WordPress VM. That is the simplest setup because the tunnel can send traffic to Caddy at `http://127.0.0.1:80`.

#### 1. Confirm WordPress Works Locally First

Before adding Cloudflare, confirm Caddy and WordPress work from the LAN:

```text
http://<VM_IP>/
```

For named sites, confirm the hostname resolves locally or test with `curl` and a Host header:

```bash
curl -I -H "Host: blog.example.com" http://<VM_IP>/
```

Expected result is an HTTP response from Caddy/WordPress, not a connection failure.

#### 2. Open Cloudflare Zero Trust

In a browser:

1. Go to `https://one.dash.cloudflare.com/`.
2. Select your Cloudflare account.
3. Select the Zero Trust organization for the domain.
4. In the left navigation, go to `Networks`.
5. Select `Tunnels`.

Cloudflare sometimes changes navigation labels. If `Tunnels` is not under `Networks`, use the dashboard search for `Tunnels`.

#### 3. Create The Tunnel

In `Tunnels`:

1. Click `Create a tunnel`.
2. Choose `Cloudflared` as the tunnel type.
3. Click `Next`.
4. Enter a descriptive tunnel name, for example `wordpress-platform`.
5. Click `Save tunnel`.

#### 4. Install The Connector On The VM

Cloudflare will show install commands for different operating systems.

Choose `Debian` if the WordPress VM is Debian or Ubuntu.

The dashboard usually provides a command containing a token. It looks similar to this:

```bash
sudo cloudflared service install <CLOUDFLARE_TUNNEL_TOKEN>
```

Run the Cloudflare-provided commands on the WordPress VM over SSH:

```bash
ssh -i ~/.ssh/wordpress_01_ed25519 ubuntu@<VM_IP>
```

If you need to install `cloudflared` manually first:

```bash
curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
```

Then run the `cloudflared service install ...` command from the Cloudflare dashboard.

Do not save the tunnel token in this repo or paste it into tracked files.

### VM Rebuild Note

If you destroy and recreate the WordPress VM, reinstall the Cloudflare Tunnel connector on the new VM. The Cloudflare tunnel and public hostname entries can remain in Cloudflare, but the old VM's `cloudflared` service and connector identity are gone with the destroyed VM.

After the new VM is built and Ansible has started Caddy, run the Cloudflare-provided connector install command on the new VM, then verify:

```bash
sudo systemctl status cloudflared
curl -I http://127.0.0.1/
```

#### 5. Verify The Connector Is Online

On the VM:

```bash
sudo systemctl status cloudflared
sudo journalctl -u cloudflared --no-pager -n 50
```

In the Cloudflare dashboard, the tunnel connector should show as `Healthy` or `Connected`.

If it does not connect, check VM outbound internet access and DNS resolution.

#### 6. Add Public Hostnames

In the tunnel dashboard, go to `Public Hostnames` and add one hostname per WordPress site.

For `blog.example.com`:

```text
Subdomain: blog
Domain:    example.com
Path:      leave empty
Type:      HTTP
URL:       127.0.0.1:80
```

For `store.example.com`:

```text
Subdomain: store
Domain:    example.com
Path:      leave empty
Type:      HTTP
URL:       127.0.0.1:80
```

Use `127.0.0.1:80` only when `cloudflared` runs on the WordPress VM.

If `cloudflared` runs on another machine, use the VM IP instead:

```text
Type: HTTP
URL:  <VM_IP>:80
```

Cloudflare Tunnel sends the original hostname to Caddy, so Caddy can still route `blog.example.com` and `store.example.com` to different WordPress containers even though both public hostnames point to the same origin URL.

#### 7. Match Cloudflare Hostnames In Ansible

Every Cloudflare public hostname must match a `server_name` in `ansible/group_vars/all.yml`:

```yaml
wordpress_sites:
  - id: blog
    server_name: "blog.example.com"
    db_name: blog
    db_user: blog

  - id: store
    server_name: "store.example.com"
    db_name: store
    db_user: store
```

Deploy after changing site names:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini site.yml
```

#### 8. Test The Public URLs

From your workstation:

```bash
curl -I https://blog.example.com/
curl -I https://store.example.com/
```

Then open the sites in a browser:

```text
https://blog.example.com/
https://store.example.com/
```

If the wrong WordPress site appears, the most common cause is a mismatch between the Cloudflare public hostname and the Caddy `server_name` value in `wordpress_sites`.

#### 9. Optional: Add Cloudflare Access For Admin URLs

For stronger login protection, put Cloudflare Access in front of admin paths.

In Cloudflare Zero Trust:

1. Go to `Access` -> `Applications`.
2. Click `Add an application`.
3. Choose `Self-hosted`.
4. Name it, for example `WordPress Admin - blog`.
5. Add the application domain for the login path:

```text
blog.example.com/wp-login.php
```

6. Add another self-hosted application or path for:

```text
blog.example.com/wp-admin/*
```

7. Create an Access policy that allows only your email, group, or identity provider users.
8. Repeat for each site that needs protected admin access.

Keep WordPress 2FA enabled even when using Cloudflare Access.

### Security Notes

- Do not commit tunnel tokens.
- Do not expose the VM ports publicly if using Cloudflare Tunnel only.
- Cloudflare Tunnel protects inbound network exposure, but WordPress still needs patching, 2FA, backups, and plugin discipline.
- If using Cloudflare proxy/Tunnel HTTPS at the edge and HTTP to Caddy internally, keep `wordpress_force_ssl_admin: false` until WordPress is configured to trust the proxy headers correctly.

### Cloudflare Tunnel Troubleshooting

If the public hostname returns `502 Bad Gateway`:

- Check `sudo systemctl status cloudflared` on the VM.
- Check `sudo journalctl -u cloudflared --no-pager -n 100`.
- Confirm Caddy is listening locally with `curl -I http://127.0.0.1/` on the VM.
- Confirm the Cloudflare public hostname service URL is `http://127.0.0.1:80` when `cloudflared` runs on the VM.

If the public hostname opens the wrong WordPress site:

- Confirm the Cloudflare public hostname exactly matches `wordpress_sites[*].server_name`.
- Rerun Ansible after editing `ansible/group_vars/all.yml`.
- Check the rendered Caddyfile on the VM with `sudo cat /opt/wordpress-platform/Caddyfile`.

If page resources point to the VM private IP:

- Add or fix `url: "https://<hostname>"` for the site in `ansible/group_vars/all.yml`.
- Rerun Ansible for that site with `-e wordpress_site=<id>`.
- Clear browser cache if old CSS or image URLs were cached.

If the site works by VM IP but not through Cloudflare:

- Confirm the domain is managed by Cloudflare.
- Confirm the tunnel connector is healthy in Zero Trust.
- Confirm the public hostname exists under the tunnel.
- Confirm there is no conflicting DNS record for the same hostname.

If `/wp-admin/` or `/wp-login.php` returns `403`:

- This can be expected because `wordpress_admin_private_only: true` restricts admin paths to private source IPs at Caddy.
- Cloudflare requests may arrive from Cloudflare IP ranges, not private LAN IPs.
- If using Cloudflare Tunnel plus Cloudflare Access for admin protection, you may need to set `wordpress_admin_private_only: false` and rely on Cloudflare Access plus WordPress 2FA.
- Do not disable the private admin restriction for direct public routing unless another admin protection layer is in place.

If the browser shows `ERR_TOO_MANY_REDIRECTS`:

- Confirm the site `url` is set to the public HTTPS URL in `ansible/group_vars/all.yml`.
- Rerun Ansible for the affected site so WordPress receives the proxy HTTPS configuration.
- Clear cookies for the affected domain or test in a private browser window.
- In Cloudflare, avoid SSL/TLS modes that force conflicting redirects. Cloudflare Tunnel normally terminates HTTPS at Cloudflare and sends HTTP to the tunnel origin; WordPress must trust the forwarded HTTPS headers.

## Choosing A Path

Use direct routing if:

- You control DNS and firewall forwarding.
- You want standard public web hosting behavior.
- You are comfortable exposing ports `80` and `443` to the VM.

Use Cloudflare Tunnel if:

- You do not want inbound port forwards.
- Your ISP uses CGNAT or blocks inbound ports.
- You want Cloudflare Access in front of admin paths.
- You are comfortable depending on Cloudflare for public access.
