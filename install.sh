#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  NSAI Installer — Linux & macOS                             ║
# ║  Not So Artificial Intelligence Ultrabot (NUB)              ║
# ║  https://nsai.tech | nub@nsai.tech                         ║
# ╚══════════════════════════════════════════════════════════════╝
set -e

REPO_URL="https://github.com/Go-on-now-git/nsai-portal"
INSTALL_DIR="$HOME/nsai-portal"
NUB_VERSION="1.0.0"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

banner() {
  echo ""
  echo -e "${BLUE}${BOLD}╔══════════════════════════════════════╗${NC}"
  echo -e "${BLUE}${BOLD}║  NSAI ⚡  Not So AI — NUB Installer  ║${NC}"
  echo -e "${BLUE}${BOLD}╚══════════════════════════════════════╝${NC}"
  echo ""
}

ok()   { echo -e "${GREEN}  ✓${NC} $1"; }
info() { echo -e "${CYAN}  →${NC} $1"; }
err()  { echo -e "${RED}  ✗${NC} $1"; exit 1; }
ask()  { echo -e "${BOLD}$1${NC}"; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo "mac" ;;
    Linux)
      if grep -qi android /proc/version 2>/dev/null; then echo "android"
      else echo "linux"; fi ;;
    *) echo "unknown" ;;
  esac
}

install_node() {
  if command -v node &>/dev/null && node --version | grep -qE 'v1[6-9]|v2[0-9]'; then
    ok "Node.js $(node --version) already installed"
    return
  fi
  info "Installing Node.js 20 LTS..."
  OS=$(detect_os)
  if [ "$OS" = "mac" ]; then
    if ! command -v brew &>/dev/null; then
      info "Installing Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install node@20
  elif [ "$OS" = "linux" ] || [ "$OS" = "android" ]; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
  else
    err "Unsupported OS. Install Node.js 20 manually from nodejs.org then re-run."
  fi
  ok "Node.js $(node --version) installed"
}

install_pm2() {
  if command -v pm2 &>/dev/null; then
    ok "PM2 already installed"
    return
  fi
  info "Installing PM2 (process manager)..."
  npm install -g pm2
  ok "PM2 installed"
}

clone_or_update() {
  if [ -d "$INSTALL_DIR/.git" ]; then
    info "Updating existing installation..."
    git -C "$INSTALL_DIR" pull
  else
    info "Downloading NUB..."
    git clone "$REPO_URL" "$INSTALL_DIR"
  fi
  ok "Files ready at $INSTALL_DIR"
}

configure() {
  ENV_FILE="$INSTALL_DIR/.env.nsai"

  if [ -f "$ENV_FILE" ]; then
    info "Existing .env.nsai found — skipping credential setup."
    return
  fi

  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}  Configure Your NUB Instance${NC}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""

  while true; do
    ask "Anthropic API Key (get one free at console.anthropic.com):"
    read -r ANTHROPIC_KEY
    ANTHROPIC_KEY="${ANTHROPIC_KEY// /}"
    if [[ "$ANTHROPIC_KEY" =~ ^sk-ant- ]]; then break; fi
    echo -e "${RED}  ✗${NC} Key must start with sk-ant-. Try again."
  done

  while true; do
    ask "Portal Access PIN (4+ digits, numbers only):"
    read -r PORTAL_PIN
    PORTAL_PIN="${PORTAL_PIN// /}"
    if [[ "$PORTAL_PIN" =~ ^[0-9]{4,}$ ]]; then break; fi
    echo -e "${RED}  ✗${NC} PIN must be 4+ digits. Try again."
  done

  ask "Your Telegram User ID (optional, for NUB notifications — press Enter to skip):"
  read -r TELEGRAM_ID
  TELEGRAM_ID="${TELEGRAM_ID// /}"

  ask "Port to run on (default: 8080):"
  read -r PORT_INPUT
  PORT_INPUT="${PORT_INPUT// /}"
  PORT_INPUT="${PORT_INPUT:-8080}"
  if ! [[ "$PORT_INPUT" =~ ^[0-9]+$ ]] || [ "$PORT_INPUT" -lt 1024 ] || [ "$PORT_INPUT" -gt 65535 ]; then
    PORT_INPUT="8080"
  fi

  SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))" 2>/dev/null || openssl rand -hex 32)

  # Write env file — use printf to handle special chars safely
  {
    printf 'ANTHROPIC_API_KEY=%s\n' "$ANTHROPIC_KEY"
    printf 'PORTAL_PIN=%s\n' "$PORTAL_PIN"
    printf 'PORTAL_SECRET=%s\n' "$SECRET"
    printf 'TELEGRAM_ID=%s\n' "$TELEGRAM_ID"
    printf 'PORT=%s\n' "$PORT_INPUT"
  } > "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  ok "Configuration saved to .env.nsai"
}

launch() {
  cd "$INSTALL_DIR"
  info "Installing dependencies..."
  npm install --silent
  info "Starting NUB with PM2..."
  pm2 delete nsai-portal 2>/dev/null || true
  PORT=$(grep '^PORT=' "$INSTALL_DIR/.env.nsai" 2>/dev/null | cut -d= -f2)
  PORT="${PORT:-8080}"
  pm2 start server.js --name nsai-portal
  pm2 save
  ok "NUB is running on port $PORT"
}

print_success() {
  PORT=$(grep '^PORT=' "$INSTALL_DIR/.env.nsai" 2>/dev/null | cut -d= -f2)
  PORT="${PORT:-8080}"
  LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ipconfig getifaddr en0 2>/dev/null || echo "your-local-ip")
  echo ""
  echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}${BOLD}║  NUB is live. #StayAbove               ║${NC}"
  echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  Local:    ${CYAN}http://localhost:${PORT}${NC}"
  echo -e "  Network:  ${CYAN}http://${LOCAL_IP}:${PORT}${NC}  (share this on your WiFi)"
  echo ""
  echo -e "  ${BOLD}Useful commands:${NC}"
  echo -e "  pm2 logs nsai-portal   — view live logs"
  echo -e "  pm2 restart nsai-portal — restart"
  echo -e "  pm2 stop nsai-portal   — stop"
  echo ""
  echo -e "  nsai.tech  |  nub@nsai.tech  |  #StayAbove"
  echo ""
}

main() {
  banner
  info "Checking system..."
  install_node
  install_pm2
  clone_or_update
  configure
  launch
  print_success
}

main
