# Xray VPN Package with VLESS + REALITY

## Description

This package provides an xray (VPN) setup with VLESS protocol and REALITY for enhanced security and performance.

## Prerequisites

- Nix package manager
- (Optional) Google Chrome browser for proxy configuration and (SwitchyOmega extension)
- (Optional) Android v2rayNG

- Android v2rayNG example config. Import from copy buffer
```
vless://ec209473-9f70-474f-a686-cc69496118fa@133.333.333.33:1090?security=reality&encryption=none&alpn=http/1.1&pbk=VsuXH2iP8dUzJbsKO9BxLOmYwS_jyIjxPrQtfC_S-A0&headerType=none&fp=firefox&spx=%2F&type=tcp&flow=xtls-rprx-vision&sni=www.google.com&sid=114514#x-ray+vless+tcp+reality
```

## Installation and Setup

- install nix
```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

### Generate Configuration

1. Generate private and public keys along with UUID:

```bash
nix run .#generate-config
# or
nix run "github:back2nix/nix-shell?dir=flake_xray#generate-config"
```

2. Replace `xrayConfig` in `flake.nix` with the generated keys.

Note: If you don't generate a config, a default example for localhost with sample keys will be used.

### Usage

Run the following commands based on your needs:

```bash
# Start the server
nix run .#server

# Start the client
nix run .#client

# Test the proxy (similar to 'proxychains4 curl https://ifconfig.me')
nix run .#run-through-proxy
```

Alternatively, you can use these commands:

```bash
nix run "github:back2nix/nix-shell?dir=flake_xray#server"
nix run "github:back2nix/nix-shell?dir=flake_xray#client"

# for check proxy. analog 'proxychains4 curl https://ifconfig.me'
nix run "github:back2nix/nix-shell?dir=flake_xray#run-through-proxy"
```

## Chrome Proxy Configuration

For easy proxy management in Google Chrome:

1. Install the SwitchyOmega extension from the Chrome Web Store.
2. Configure the extension with the following proxy settings:
   - SOCKS5 proxy: `127.0.0.1` with port `1091`
   - HTTP proxy: `127.0.0.1` with port `1092`

## Troubleshooting

### Nix Command and Flakes Features

If you encounter the following error:

```
error: experimental Nix feature 'nix-command' is disabled; add '--extra-experimental-features nix-command' to enable it
error: experimental Nix feature 'flakes' is disabled; add '--extra-experimental-features flakes' to enable it
```

Use these modified commands:

```bash
nix run --extra-experimental-features nix-command --extra-experimental-features flakes "github:back2nix/nix-shell?dir=flake_xray#generate-config"
nix run --extra-experimental-features nix-command --extra-experimental-features flakes "github:back2nix/nix-shell?dir=flake_xray#server"
nix run --extra-experimental-features nix-command --extra-experimental-features flakes "github:back2nix/nix-shell?dir=flake_xray#client"
nix run --extra-experimental-features nix-command --extra-experimental-features flakes "github:back2nix/nix-shell?dir=flake_xray#run-through-proxy"
```

## Updating

To update the flake and ensure you have the latest version:

```bash
nix run --refresh --extra-experimental-features nix-command --extra-experimental-features flakes "github:back2nix/nix-shell?dir=flake_xray#generate-config"
nix run --refresh --extra-experimental-features nix-command --extra-experimental-features flakes "github:back2nix/nix-shell?dir=flake_xray#server"
nix run --refresh --extra-experimental-features nix-command --extra-experimental-features flakes "github:back2nix/nix-shell?dir=flake_xray#client"
nix run --refresh --extra-experimental-features nix-command --extra-experimental-features flakes "github:back2nix/nix-shell?dir=flake_xray#run-through-proxy"
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
