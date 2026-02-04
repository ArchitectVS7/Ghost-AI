#!/bin/bash
#
# Ghost AI System - Pre-flight Setup Script
#
# This script runs on your HOST machine BEFORE creating the USB.
# It downloads all necessary files and prepares the USB for automated setup.
#
# Usage: ./ghost-ai-preflight.sh /path/to/usb/device
# Example: ./ghost-ai-preflight.sh /dev/sdb
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] ✓${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠${NC} $1"
}

# Check arguments
if [ -z "$1" ]; then
    log_error "Usage: $0 /dev/sdX"
    log_error "Example: $0 /dev/sdb"
    exit 1
fi

USB_DEVICE=$1

# Check if device exists
if [ ! -b "$USB_DEVICE" ]; then
    log_error "Device $USB_DEVICE does not exist"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    log_error "Please run as root (use sudo)"
    exit 1
fi

# Safety check
log ""
log "========================================="
log "Ghost AI System - Pre-flight Setup"
log "========================================="
log ""
log "Target device: $USB_DEVICE"
lsblk "$USB_DEVICE"
log ""
log_warning "⚠️  WARNING: ALL DATA ON $USB_DEVICE WILL BE ERASED!"
log ""
read -p "Type 'YES' to continue: " CONFIRM

if [ "$CONFIRM" != "YES" ]; then
    log "Cancelled by user"
    exit 0
fi

WORK_DIR="$HOME/ghost-ai-preflight"
DOWNLOAD_DIR="$WORK_DIR/downloads"

mkdir -p "$DOWNLOAD_DIR"

log ""
log "Working directory: $WORK_DIR"
log ""

# ============================================================================
# STEP 1: Download Ubuntu ISO
# ============================================================================
log "STEP 1: Downloading Ubuntu 24.04 ISO (~6GB)..."

UBUNTU_ISO="$DOWNLOAD_DIR/ubuntu-24.04-desktop-amd64.iso"

if [ -f "$UBUNTU_ISO" ]; then
    log_warning "Ubuntu ISO already exists, skipping download"
else
    wget -O "$UBUNTU_ISO" https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso || {
        log_error "Failed to download Ubuntu ISO"
        exit 1
    }
    log_success "Ubuntu ISO downloaded"
fi

# Verify ISO (optional but recommended)
log "Verifying ISO checksum..."
cd "$DOWNLOAD_DIR"
wget -q https://releases.ubuntu.com/24.04/SHA256SUMS
if sha256sum -c SHA256SUMS 2>&1 | grep -q "ubuntu-24.04-desktop-amd64.iso: OK"; then
    log_success "ISO verified successfully"
else
    log_warning "ISO verification failed (might still work)"
fi
cd - > /dev/null

# ============================================================================
# STEP 2: Write ISO to USB
# ============================================================================
log ""
log "STEP 2: Writing Ubuntu to USB drive..."
log "This will take 10-20 minutes..."

# Unmount any mounted partitions
umount ${USB_DEVICE}* 2>/dev/null || true

# Write ISO
dd if="$UBUNTU_ISO" of="$USB_DEVICE" bs=4M status=progress oflag=sync conv=fdatasync || {
    log_error "Failed to write ISO to USB"
    exit 1
}

# Sync
sync

log_success "Ubuntu written to USB"

# ============================================================================
# STEP 3: Download orchestrator script
# ============================================================================
log ""
log "STEP 3: Preparing automation scripts..."

# Create a temporary mount point
TMP_MOUNT="/mnt/ghost-ai-usb-tmp"
mkdir -p "$TMP_MOUNT"

# Wait for system to recognize new partitions
sleep 3
partprobe "$USB_DEVICE" 2>/dev/null || true
sleep 2

# Find the ESP partition (should be the first partition)
USB_PART="${USB_DEVICE}1"

if [ ! -b "$USB_PART" ]; then
    # Try alternative naming (e.g., nvme devices)
    USB_PART="${USB_DEVICE}p1"
fi

# Try to mount it
if mount "$USB_PART" "$TMP_MOUNT" 2>/dev/null; then
    log_success "Mounted USB partition"
    
    # Copy orchestrator script
    if [ -f "./ghost-ai-orchestrator.sh" ]; then
        cp ./ghost-ai-orchestrator.sh "$TMP_MOUNT/" || log_warning "Could not copy orchestrator to USB"
        chmod +x "$TMP_MOUNT/ghost-ai-orchestrator.sh" 2>/dev/null || true
        log_success "Orchestrator script copied to USB"
    else
        log_warning "Orchestrator script not found in current directory"
        log "You'll need to copy it manually after booting Ubuntu"
    fi
    
    # Create autostart instructions
    cat > "$TMP_MOUNT/AUTOSTART-INSTRUCTIONS.txt" << 'EOF'
===========================================
Ghost AI System - Automated Setup
===========================================

After booting Ubuntu from this USB:

1. Select "Try Ubuntu" (don't install yet)

2. Open Terminal

3. Run the automated installer:
   
   cd /media/ubuntu/*
   sudo bash ghost-ai-orchestrator.sh

4. Follow the prompts

The script will:
- Install Ubuntu to this USB drive
- Download and configure all AI models
- Set up offline Wikipedia
- Configure security and privacy
- Create all necessary scripts

Total time: 2-4 hours (mostly automated)

For manual installation, see the setup guide.
EOF
    
    umount "$TMP_MOUNT"
    log_success "Instructions added to USB"
else
    log_warning "Could not mount USB to copy scripts"
    log "You'll need to copy the orchestrator script manually"
fi

rmdir "$TMP_MOUNT" 2>/dev/null || true

# ============================================================================
# STEP 4: Download large files (optional)
# ============================================================================
log ""
log "STEP 4: Pre-download large files (optional)..."
log ""
log "Would you like to pre-download large files now?"
log "This will save time during USB setup but requires ~100GB disk space."
log ""
log "Files to download:"
log "- AI models (~50GB)"
log "- Offline Wikipedia (~96GB)"
log ""
read -p "Pre-download now? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Downloading files to $DOWNLOAD_DIR..."
    log "You can transfer these to the USB later to speed up setup"
    
    # Create download script
    cat > "$DOWNLOAD_DIR/download-all.sh" << 'EOF'
#!/bin/bash
echo "Downloading AI models and Wikipedia..."
echo "This will take several hours..."

mkdir -p models wikipedia

# Download Wikipedia
cd wikipedia
wget -c https://download.kiwix.org/zim/wikipedia/wikipedia_en_all_nopic_2024-01.zim
cd ..

echo "Download complete!"
echo ""
echo "To use these files during setup:"
echo "1. Copy this entire 'downloads' folder to a USB drive"
echo "2. During automated setup, copy files to appropriate locations"
echo ""
EOF
    
    chmod +x "$DOWNLOAD_DIR/download-all.sh"
    
    log "Starting background downloads..."
    log "You can monitor progress in: $DOWNLOAD_DIR"
    
    # Start download in background
    nohup bash "$DOWNLOAD_DIR/download-all.sh" > "$DOWNLOAD_DIR/download.log" 2>&1 &
    
    log_success "Downloads started in background (PID: $!)"
    log "Check progress: tail -f $DOWNLOAD_DIR/download.log"
else
    log "Skipping pre-downloads"
    log "Files will be downloaded during automated setup"
fi

# ============================================================================
# COMPLETION
# ============================================================================
log ""
log "========================================="
log "Pre-flight Setup Complete!"
log "========================================="
log ""
log_success "Bootable USB created successfully!"
log ""
log "Next steps:"
log ""
log "1. Boot from USB drive:"
log "   - Insert USB into target computer"
log "   - Restart and select USB in boot menu (F2/F12/DEL)"
log "   - Select 'Try Ubuntu'"
log ""
log "2. Run automated setup:"
log "   - Open Terminal"
log "   - cd /media/ubuntu/*"
log "   - sudo bash ghost-ai-orchestrator.sh"
log ""
log "3. Or install manually:"
log "   - Follow the setup guide"
log ""
log "Files saved in: $WORK_DIR"
log ""
log "⚠️  IMPORTANT: Keep the USB physically secure during setup"
log ""
log_success "Ready to create your Ghost AI System!"
log ""

exit 0
