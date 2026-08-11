# Install OpenTofu

OpenTofu is used from the `opentofu/` directory to provision the Proxmox VM.

## Verify First

Check whether OpenTofu is already installed:

```bash
tofu version
```

This project expects OpenTofu `1.8.0` or newer.

## Windows

Use `winget` from PowerShell:

```powershell
winget install OpenTofu.Tofu
```

Close and reopen the terminal, then verify:

```powershell
tofu version
```

If `winget` is not available, install from the OpenTofu releases page and make sure the folder containing `tofu.exe` is on your `PATH`.

## WSL Or Ubuntu/Debian

Install required package tools:

```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
```

Add the OpenTofu package repository:

```bash
curl -fsSL https://get.opentofu.org/opentofu.gpg | sudo gpg --dearmor -o /usr/share/keyrings/opentofu.gpg
curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/opentofu-repo.gpg
echo "deb [signed-by=/usr/share/keyrings/opentofu.gpg,/usr/share/keyrings/opentofu-repo.gpg] https://packages.opentofu.org/opentofu/tofu/any/ any main" | sudo tee /etc/apt/sources.list.d/opentofu.list
```

Install OpenTofu:

```bash
sudo apt-get update
sudo apt-get install -y tofu
tofu version
```

## macOS

Use Homebrew:

```bash
brew update
brew install opentofu
tofu version
```

## Project Check

From the repository root:

```bash
cd opentofu
tofu fmt -check
tofu init
tofu validate
```

`tofu init` downloads the Proxmox provider into `opentofu/.terraform/`, which is ignored by git.
