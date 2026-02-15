# homebrew-frp

Homebrew tap for [frp](https://github.com/fatedier/frp) (fast reverse proxy). Provides separate formulae for `frps` (server) and `frpc` (client).

## Install

```bash
brew tap jacobrichard/frp

# Install server, client, or both
brew install frps
brew install frpc
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

Services do not start automatically after install.

```bash
# Start and restart at login
brew services start frps
brew services start frpc

# Stop
brew services stop frps
brew services stop frpc

# Check status
brew services list
```

## Service behavior

- Services restart automatically if the process exits
- Services do **not** start on boot/login unless started with `brew services start`
- Logs are written to `$(brew --prefix)/var/log/frps.log` and `$(brew --prefix)/var/log/frpc.log`

## Uninstall

```bash
brew services stop frps frpc
brew uninstall frps frpc
brew untap jacobrichard/frp
```
