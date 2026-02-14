#!/bin/bash
#
# Ghost AI System - Hardware Detection
#
# Detects system hardware and outputs a profile for installation selection
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[DETECT]${NC} $1"; }
log_success() { echo -e "${GREEN}[DETECT] ✓${NC} $1"; }
log_warning() { echo -e "${YELLOW}[DETECT] ⚠${NC} $1"; }

# Detect CPU Architecture
detect_cpu_arch() {
    local arch=$(uname -m)
    case "$arch" in
        x86_64|amd64)
            echo "x86_64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Detect RAM (in GB)
detect_ram() {
    local ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local ram_gb=$((ram_kb / 1024 / 1024))
    echo "$ram_gb"
}

# Detect GPU
detect_gpu() {
    # Check for NVIDIA
    if command -v nvidia-smi &> /dev/null; then
        echo "nvidia"
        return
    fi

    # Check for AMD
    if lspci 2>/dev/null | grep -i "VGA.*AMD" &> /dev/null; then
        echo "amd"
        return
    fi

    # Check for Apple Silicon (on ARM64)
    if [ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ]; then
        # Check if running on macOS or Asahi Linux with Apple GPU
        if [ -d "/sys/class/drm" ] && ls /sys/class/drm/ | grep -q "card"; then
            echo "apple"
            return
        fi
    fi

    echo "cpu"
}

# Detect available disk space (in GB)
detect_disk_space() {
    local available_kb=$(df / | awk 'NR==2 {print $4}')
    local available_gb=$((available_kb / 1024 / 1024))
    echo "$available_gb"
}

# Detect CPU cores
detect_cpu_cores() {
    nproc
}

# Main detection
main() {
    log "Detecting hardware configuration..."
    echo ""

    ARCH=$(detect_cpu_arch)
    RAM=$(detect_ram)
    GPU=$(detect_gpu)
    DISK=$(detect_disk_space)
    CORES=$(detect_cpu_cores)

    # Display results
    log_success "Hardware Detection Complete"
    echo ""
    echo "================================"
    echo "  CPU Architecture: $ARCH"
    echo "  RAM:              ${RAM}GB"
    echo "  GPU:              $GPU"
    echo "  CPU Cores:        $CORES"
    echo "  Disk Available:   ${DISK}GB"
    echo "================================"
    echo ""

    # Determine recommended tier
    if [ "$RAM" -lt 8 ]; then
        TIER="minimal"
        log_warning "Low RAM detected. Recommended tier: MINIMAL (small models only)"
    elif [ "$RAM" -lt 16 ]; then
        TIER="basic"
        log "Recommended tier: BASIC (7B-13B models)"
    elif [ "$RAM" -lt 32 ]; then
        TIER="standard"
        log "Recommended tier: STANDARD (7B-22B models)"
    else
        TIER="full"
        log_success "High RAM detected. Recommended tier: FULL (up to 70B models)"
    fi

    # Check disk space
    if [ "$DISK" -lt 100 ]; then
        log_warning "Low disk space. May need to skip optional components."
    fi

    # Output JSON for programmatic use
    if [ "$1" = "--json" ]; then
        cat << EOF
{
  "arch": "$ARCH",
  "ram_gb": $RAM,
  "gpu": "$GPU",
  "cores": $CORES,
  "disk_gb": $DISK,
  "recommended_tier": "$TIER"
}
EOF
    fi

    # Export for other scripts
    echo "export DETECTED_ARCH='$ARCH'" > /tmp/ghost-hardware.env
    echo "export DETECTED_RAM='$RAM'" >> /tmp/ghost-hardware.env
    echo "export DETECTED_GPU='$GPU'" >> /tmp/ghost-hardware.env
    echo "export DETECTED_DISK='$DISK'" >> /tmp/ghost-hardware.env
    echo "export DETECTED_CORES='$CORES'" >> /tmp/ghost-hardware.env
    echo "export RECOMMENDED_TIER='$TIER'" >> /tmp/ghost-hardware.env
}

main "$@"
