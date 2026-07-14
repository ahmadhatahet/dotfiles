# dotfiles

Personal machine setup scripts. This repo is public — never commit real
usernames, hostnames, or IPs. Personal SSH hosts go in `ssh_config.local`
(gitignored), not in the scripts.

## Quick start

Clone the repo, then run the one script for your system:

### macOS / WSL / Linux (cloud GPU box)

```bash
git clone git@github.com:ahmadhatahet/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

`install.sh` auto-detects the OS and runs the right setup:
| Detected as | What it does |
|---|---|
| macOS (`Darwin`) | Homebrew + `Brewfile`, oh-my-zsh, theme, aliases, rustup, SSH key |
| WSL (`Linux` + `microsoft` in `/proc/version`) | zsh, oh-my-zsh, powerline fonts, dircolors, theme, aliases, SSH key |
| Bare Linux (cloud/GPU box) | apt build tools + CUDA + nvtop, oh-my-zsh, rust, uv, Homebrew-on-Linux, llama.cpp, theme, aliases, SSH key (self-elevates to root as needed) |

### Native Windows (PowerShell, no WSL)

```powershell
git clone git@github.com:ahmadhatahet/dotfiles.git $HOME\dotfiles
cd $HOME\dotfiles
.\install.ps1
```

Installs Scoop, git, uv, the MesloLGS NF font, PowerShell profile
aliases, and generates an SSH key.

## Personal SSH hosts

Both scripts look for `ssh_config.local` next to themselves and append
it to `~/.ssh/config` if present. It is gitignored and never committed.

```bash
cp ssh_config.local.example ssh_config.local
# edit ssh_config.local with your real usernames/hostnames/IPs
```

## Other scripts (not part of initial setup)

- `install_miniconda.sh` — installs Miniconda on Linux.
- `backup_to_external_drive.ps1` — incremental robocopy backup of `D:\` to an external drive (Windows).
