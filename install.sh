#!/bin/bash
#
# Ghost AI System - Unified Installer
#
# Main entry point for Ghost AI installation
# Detects hardware and runs appropriate orchestrator
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${BLUE}[INSTALL]${NC} $1"; }
log_success() { echo -e "${GREEN}[INSTALL] ✓${NC} $1"; }
log_error() { echo -e "${RED}[INSTALL] ✗${NC} $1"; }
log_warning() { echo -e "${YELLOW}[INSTALL] ⚠${NC} $1"; }

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Banner
clear
echo -e "${CYAN}"
cat << 'EOF'
  ____  _               _      _    ___
 / ___|| |__   ___  ___| |_   / \  |_ _|
| |  _ | '_ \ / _ \/ __| __| / _ \  | |
| |_| || | | | (_) \__ \ |_ / ___ \ | |
 \____||_| |_|\___/|___/\__/_/   \_\___|

  Offline AI System - Automated Installer
EOF
echo -e "${NC}"
echo ""

# Run hardware detection
log "Running hardware detection..."
./detect-hardware.sh

# Load detected hardware
if [ -f /tmp/ghost-hardware.env ]; then
    source /tmp/ghost-hardware.env
else
    log_error "Hardware detection failed"
    exit 1
fi

echo ""
log "Detected Configuration:"
echo "  - Architecture: $DETECTED_ARCH"
echo "  - RAM: ${DETECTED_RAM}GB"
echo "  - GPU: $DETECTED_GPU"
echo "  - Recommended Tier: $RECOMMENDED_TIER"
echo ""

# Determine orchestrator
case "$DETECTED_ARCH" in
    x86_64)
        ORCHESTRATOR="./orchestrator-x86.sh"
        ARCH_NAME="x86_64 (Intel/AMD)"
        ;;
    arm64)
        ORCHESTRATOR="./orchestrator-arm64.sh"
        ARCH_NAME="ARM64 (Apple Silicon)"
        ;;
    *)
        log_error "Unsupported architecture: $DETECTED_ARCH"
        exit 1
        ;;
esac

# Ask user for installation mode
echo "================================"
echo "  Installation Options"
echo "================================"
echo ""
echo "1) AUTO - Use detected hardware ($ARCH_NAME)"
echo "2) MANUAL - Choose architecture manually"
echo "3) CANCEL - Exit installer"
echo ""
read -p "Select option [1/2/3]: " choice

case $choice in
    1)
        log "Auto-install mode selected"
        ;;
    2)
        log "Manual selection mode"
        echo ""
        echo "Select architecture:"
        echo "1) x86_64 (Intel/AMD processors)"
        echo "2) ARM64 (Apple Silicon, ARM servers)"
        echo ""
        read -p "Select [1/2]: " arch_choice

        case $arch_choice in
            1)
                ORCHESTRATOR="./orchestrator-x86.sh"
                ARCH_NAME="x86_64"
                ;;
            2)
                ORCHESTRATOR="./orchestrator-arm64.sh"
                ARCH_NAME="ARM64"
                ;;
            *)
                log_error "Invalid selection"
                exit 1
                ;;
        esac
        ;;
    3)
        log "Installation cancelled"
        exit 0
        ;;
    *)
        log_error "Invalid option"
        exit 1
        ;;
esac

echo ""
log "Will install Ghost AI for: $ARCH_NAME"
echo ""

# Confirm installation
echo "================================"
echo "  Ready to Install"
echo "================================"
echo ""
echo "This will install:"
echo "  - Ubuntu packages and updates"
echo "  - Ollama (local LLM engine)"
echo "  - AI models (based on your RAM)"
echo "  - OpenClaw (AI assistant)"
echo "  - Whisper (speech-to-text)"
echo "  - Piper TTS (text-to-speech)"
echo "  - Security configurations"
echo ""
echo "Estimated time: 2-4 hours (mostly downloads)"
echo "Internet required during installation"
echo ""
read -p "Continue with installation? [y/N]: " confirm

if [[ ! $confirm =~ ^[Yy]$ ]]; then
    log "Installation cancelled"
    exit 0
fi

# Check if orchestrator exists
if [ ! -f "$ORCHESTRATOR" ]; then
    log_error "Orchestrator not found: $ORCHESTRATOR"
    log_error "Make sure all files are present in the repository"
    exit 1
fi

# Make orchestrator executable
chmod +x "$ORCHESTRATOR"

# Run the orchestrator
log_success "Starting installation..."
echo ""

# Pass hardware info to orchestrator
export DETECTED_ARCH
export DETECTED_RAM
export DETECTED_GPU
export DETECTED_DISK
export RECOMMENDED_TIER

exec "$ORCHESTRATOR" "$@"
