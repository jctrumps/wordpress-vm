# WSL Setup

Use WSL with Ubuntu as the recommended control environment when deploying this project from Windows. Ansible works best from Linux, and using WSL keeps SSH, Ansible, and OpenTofu commands consistent with server-side documentation.

## 1. Install WSL And Ubuntu

From Windows PowerShell as your normal user:

```powershell
wsl --install -d Ubuntu
```

Restart Windows if prompted.

Open Ubuntu from the Start menu and create your Linux username and password.

If WSL is already installed, list available distributions:

```powershell
wsl --list --online
```

Install Ubuntu if needed:

```powershell
wsl --install -d Ubuntu
```

## 2. Update Ubuntu

Inside Ubuntu/WSL:

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl git gnupg openssh-client
```

## 3. Confirm WSL Version

From Windows PowerShell:

```powershell
wsl --status
wsl --list --verbose
```

*I ran the following to determine current default:
wsl --list

Ubuntu should normally run as WSL 2. If it is WSL 1, convert it:

```powershell
wsl --set-version Ubuntu 2
```

*I set the default with the following command:
wsl --set-default ubuntu

## 4. Choose Where The Repo Lives

Recommended: keep the repo inside the WSL Linux filesystem for better performance and file permissions.

Example inside Ubuntu:

```bash
mkdir -p ~/projects
cd ~/projects
git clone <REPOSITORY_URL> wordpress
cd wordpress
```

Alternative: access the Windows checkout from WSL:

```bash
cd /mnt/c/web-projects/wordpress
```

The Windows path works, but Linux tools are usually faster and more reliable when the repo is under `~/projects` inside WSL.

## 5. Configure Git In WSL

Inside Ubuntu:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global init.defaultBranch main
```

Skip or adjust these values if Git is already configured.

## 6. Set Up SSH Keys

If you already created the project SSH key in Windows, copy it into WSL:

```bash
mkdir -p ~/.ssh
cp /mnt/c/Users/<YOUR_NAME>/.ssh/wordpress_01_ed25519 ~/.ssh/wordpress_01_ed25519
cp /mnt/c/Users/<YOUR_NAME>/.ssh/wordpress_01_ed25519.pub ~/.ssh/wordpress_01_ed25519.pub
chmod 700 ~/.ssh
chmod 600 ~/.ssh/wordpress_01_ed25519
chmod 644 ~/.ssh/wordpress_01_ed25519.pub
```

If you need to create a new key inside WSL:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/wordpress_01_ed25519 -C "wordpress-01"
```

The public key path for OpenTofu from WSL is:

```hcl
vm_ssh_public_key_path = "~/.ssh/wordpress_01_ed25519.pub"
```

## 7. Install Project Tools

Install OpenTofu:

- See `docs/install-opentofu.md`.

Install Ansible:

- See `docs/install-ansible.md`.

Verify both tools inside WSL:

```bash
tofu version
ansible-playbook --version
```

## 8. Access The Repo From Windows Editors

If the repo lives inside WSL, open it from Windows using the WSL path.

From Ubuntu inside the repo:

```bash
explorer.exe .
```

For VS Code, if installed:

```bash
code .
```

Use the WSL extension when editing WSL files in VS Code.

## 9. Run Project Checks

From the repo root inside WSL:

```bash
cd opentofu
tofu fmt -check
tofu init
tofu validate
```

Then check Ansible:

```bash
cd ../ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini.example --syntax-check site.yml
```

## 10. Common Issues

If `tofu` or `ansible-playbook` is not found, close and reopen Ubuntu after installation, then check your `PATH`.

If SSH fails because of permissions, make sure the private key is not on `/mnt/c` for Ansible use. Copy it to `~/.ssh` and run `chmod 600 ~/.ssh/wordpress_01_ed25519`.

If Ansible ignores `ansible.cfg` while running under `/mnt/c/...`, use explicit config and inventory paths:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible -i inventory.ini wordpress -m ping
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini site.yml
```

If file operations are slow, move the repo from `/mnt/c/...` into the WSL filesystem under `~/projects/...`.

If DNS or package installs fail in WSL, restart WSL from PowerShell:

```powershell
wsl --shutdown
```

Then reopen Ubuntu and retry.
