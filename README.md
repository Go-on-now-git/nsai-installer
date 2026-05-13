# NUB Installer — NSAI

**Not So Artificial Intelligence Ultrabot** — your self-hosted AI operator.

## Quick Install

### Linux / macOS
```bash
bash install.sh
```

### Windows (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

## What You'll Need
- **Anthropic API Key** — get one free at [console.anthropic.com](https://console.anthropic.com)
- A 4+ digit PIN to protect your portal
- Node.js 16+ (installer will install if missing)

## After Install
Your NUB portal runs at `http://localhost:8080` (or whichever port you chose).

- `pm2 logs nsai-portal` — view live logs
- `pm2 restart nsai-portal` — restart
- `pm2 stop nsai-portal` — stop

## Support
- Email: nub@nsai.tech
- Site: nsai.tech
