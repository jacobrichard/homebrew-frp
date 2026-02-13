# homebrew-frp

Homebrew tap for [frp](https://github.com/fatedier/frp) (fast reverse proxy). Installs both `frps` (server) and `frpc` (client) with service definitions for macOS and Linux.

## Install

```bash
brew tap jacobrichard/frp
brew install frp
```

## Configuration

Config files are installed to `$(brew --prefix)/etc/frp/`:

| File | Description |
|------|-------------|
| `frps.toml` | Server config |
| `frpc.toml` | Client config |
| `frps_full_example.toml` | Server config with all options documented |
| `frpc_full_example.toml` | Client config with all options documented |

Edit the config before starting a service:

```bash
# Server — set the bind port
$EDITOR $(brew --prefix)/etc/frp/frps.toml

# Client — set the server address and define proxies
$EDITOR $(brew --prefix)/etc/frp/frpc.toml
```

## Running services

Services do not start automatically after install. Use the commands below to start them manually.

### macOS (launchd)

Plist files are symlinked to `~/Library/LaunchAgents/` during install.

```bash
# Start
launchctl load ~/Library/LaunchAgents/com.frp.frps.plist
launchctl load ~/Library/LaunchAgents/com.frp.frpc.plist

# Stop
launchctl unload ~/Library/LaunchAgents/com.frp.frps.plist
launchctl unload ~/Library/LaunchAgents/com.frp.frpc.plist
```

To run as a system-wide daemon instead (requires root):

```bash
sudo cp $(brew --prefix)/com.frp.frps.plist /Library/LaunchDaemons/
sudo launchctl load /Library/LaunchDaemons/com.frp.frps.plist
```

Logs are written to `$(brew --prefix)/var/log/frps.log` and `$(brew --prefix)/var/log/frpc.log`.

### Linux (systemd)

Unit files are symlinked to `/etc/systemd/system/` during install if the directory is writable. If not, link them manually:

```bash
sudo systemctl link $(brew --prefix)/lib/systemd/system/frps.service
sudo systemctl link $(brew --prefix)/lib/systemd/system/frpc.service
```

Then enable and start:

```bash
# Start and enable on boot
sudo systemctl enable --now frps
sudo systemctl enable --now frpc

# Or start without enabling on boot
sudo systemctl start frps
sudo systemctl start frpc

# Stop
sudo systemctl stop frps
sudo systemctl stop frpc

# Check status
systemctl status frps
systemctl status frpc
```

## Service behavior

- Services restart automatically if the process exits (5 second delay)
- macOS: `KeepAlive` is enabled — launchd restarts on any exit
- Linux: `Restart=always` — systemd restarts on any exit
- Services do **not** start on boot/login unless explicitly enabled

## Uninstall

```bash
brew uninstall frp
brew untap jacobrichard/frp
```

On macOS, running services are stopped and plist symlinks are cleaned up automatically. On Linux, remove any dangling symlinks or disable the services first:

```bash
sudo systemctl disable --now frps frpc
```
