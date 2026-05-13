# ╔══════════════════════════════════════════════════════════════╗
# ║  NSAI Installer — Windows (PowerShell)                      ║
# ║  Not So Artificial Intelligence Ultrabot (NUB)              ║
# ║  https://nsai.tech | nub@nsai.tech                         ║
# ╚══════════════════════════════════════════════════════════════╝
# Run as: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"
$INSTALL_DIR = "$env:USERPROFILE\nsai-portal"
$REPO_URL = "https://github.com/Go-on-now-git/nsai-portal"

function Write-OK   { param($msg) Write-Host "  [OK] $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "  --> $msg" -ForegroundColor Cyan }
function Write-Err  { param($msg) Write-Host "  [X] $msg" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "  NSAI - Not So AI - NUB Installer" -ForegroundColor Blue
Write-Host "  ====================================" -ForegroundColor Blue
Write-Host ""

# Check/install Node.js
Write-Info "Checking Node.js..."
$nodeInstalled = $false
try { $v = node --version 2>$null; if ($v -match "v(1[6-9]|[2-9]\d)") { $nodeInstalled = $true } } catch {}

if (-not $nodeInstalled) {
    Write-Info "Installing Node.js 20 LTS via winget..."
    try {
        winget install OpenJS.NodeJS.LTS --silent --accept-source-agreements --accept-package-agreements
        $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
    } catch {
        Write-Host ""
        Write-Host "  winget not available. Download Node.js from:" -ForegroundColor Yellow
        Write-Host "  https://nodejs.org/en/download" -ForegroundColor Cyan
        Write-Host "  Then re-run this script." -ForegroundColor Yellow
        Pause; exit 1
    }
}
Write-OK "Node.js $(node --version)"

# Check/install Git
$gitInstalled = $false
try { git --version | Out-Null; $gitInstalled = $true } catch {}
if (-not $gitInstalled) {
    Write-Info "Installing Git..."
    winget install Git.Git --silent --accept-source-agreements --accept-package-agreements
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
}
Write-OK "Git available"

# Install PM2
Write-Info "Installing PM2..."
npm install -g pm2 | Out-Null
Write-OK "PM2 ready"

# Clone or update
if (Test-Path "$INSTALL_DIR\.git") {
    Write-Info "Updating existing install..."
    git -C $INSTALL_DIR pull | Out-Null
} else {
    Write-Info "Downloading NUB..."
    git clone $REPO_URL $INSTALL_DIR | Out-Null
}
Write-OK "Files at $INSTALL_DIR"

# Configure
$envFile = "$INSTALL_DIR\.env.nsai"
if (-not (Test-Path $envFile)) {
    Write-Host ""
    Write-Host "  Configure Your NUB Instance" -ForegroundColor White
    Write-Host "  ============================" -ForegroundColor White
    Write-Host ""

    $anthropicKey = Read-Host "  Anthropic API Key (console.anthropic.com)"
    $portalPin    = Read-Host "  Portal Access PIN (4+ digits)"
    $telegramId   = Read-Host "  Telegram User ID (optional, press Enter to skip)"
    $portInput    = Read-Host "  Port (default 8080, press Enter for default)"
    if (-not $portInput) { $portInput = "8080" }

    $secretBytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($secretBytes)
    $secret = ($secretBytes | ForEach-Object { "{0:x2}" -f $_ }) -join ""

    @"
ANTHROPIC_API_KEY=$anthropicKey
PORTAL_PIN=$portalPin
PORTAL_SECRET=$secret
TELEGRAM_ID=$telegramId
PORT=$portInput
"@ | Set-Content $envFile -Encoding UTF8
    Write-OK "Configuration saved"
}

# Install deps & start
Set-Location $INSTALL_DIR
Write-Info "Installing dependencies..."
npm install | Out-Null

Write-Info "Starting NUB..."
pm2 delete nsai-portal 2>$null
pm2 start server.js --name nsai-portal | Out-Null
pm2 save | Out-Null

# Get local IP
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notmatch "^127\." -and $_.PrefixOrigin -eq "Dhcp" } | Select-Object -First 1).IPAddress
$port = (Select-String "^PORT=" $envFile | ForEach-Object { $_.Line.Split("=")[1] })
if (-not $port) { $port = "8080" }

Write-Host ""
Write-Host "  NUB is live. #StayAbove" -ForegroundColor Green
Write-Host "  ========================" -ForegroundColor Green
Write-Host ""
Write-Host "  Local:   http://localhost:$port" -ForegroundColor Cyan
Write-Host "  Network: http://${localIP}:$port  (share on WiFi)" -ForegroundColor Cyan
Write-Host ""
Write-Host "  pm2 logs nsai-portal      - view logs"
Write-Host "  pm2 restart nsai-portal   - restart"
Write-Host ""
Write-Host "  nsai.tech | nub@nsai.tech | #StayAbove" -ForegroundColor Blue
Write-Host ""
Pause
