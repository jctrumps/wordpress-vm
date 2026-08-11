# Install Ansible

Ansible configures the VM after OpenTofu creates it. For this project, the recommended control environment is WSL/Ubuntu or another Linux shell.

Native Windows is not a supported Ansible control node for most common setups. Use WSL if you are working from Windows.

## Verify First

Check whether Ansible is already installed:

```bash
ansible --version
ansible-playbook --version
```

## WSL Or Ubuntu/Debian

Install Ansible from apt:

```bash
sudo apt-get update
sudo apt-get install -y ansible openssh-client python3
ansible --version
```

If you need a newer Ansible than your distribution provides, install with `pipx`:

```bash
sudo apt-get update
sudo apt-get install -y pipx openssh-client python3
pipx ensurepath
pipx install --include-deps ansible
ansible --version
```

After `pipx ensurepath`, close and reopen the shell if `ansible` is not found.

## macOS

Use Homebrew:

```bash
brew update
brew install ansible
ansible --version
```

## SSH Key Setup For WSL

If your key was created in Windows PowerShell, copy the private key into WSL and restrict permissions:

```bash
mkdir -p ~/.ssh
cp /mnt/c/Users/<YOUR_NAME>/.ssh/wordpress_01_ed25519 ~/.ssh/wordpress_01_ed25519
chmod 600 ~/.ssh/wordpress_01_ed25519
```

Test SSH after the VM exists:

```bash
ssh -i ~/.ssh/wordpress_01_ed25519 ubuntu@<VM_IP>
```

Use the cloud-init username configured in `opentofu/terraform.tfvars`. The default in this repo is `ubuntu`.

## Project Check

From the repository root:

```bash
cd ansible
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook -i inventory.ini.example --syntax-check site.yml
```

The syntax check confirms the playbook is parseable. It does not contact the VM or prove that Docker, Caddy, DNS, Cloudflare, or WordPress startup will succeed in the target environment.

When running from WSL under `/mnt/c/...`, prefer the explicit `ANSIBLE_CONFIG="$PWD/ansible.cfg"` prefix because Ansible may ignore config files in Windows-mounted directories.
