# Ghost AI System - VM Test Configuration (Windows)
#
# ⚠️  PLATFORM: This script is for Windows systems only
# For Linux: use test-vm-config-linux.sh
# For macOS: use test-vm-config-macos.sh
#
# This script creates and manages a QEMU virtual machine for testing
# the Ghost AI installation process without affecting real hardware.
#
# Requirements:
# - Windows 10/11 host
# - QEMU for Windows (download from https://qemu.weilnetz.de/)
#   OR WSL2 with Ubuntu + QEMU
# - ~300GB free disk space
# - 16GB+ RAM recommended (8GB minimum)
# - CPU with virtualization support (Intel VT-x or AMD-V)
#
# Installation Option 1: QEMU for Windows
#   1. Download: https://qemu.weilnetz.de/w64/
#   2. Install to C:\Program Files\qemu
#   3. Add to PATH: C:\Program Files\qemu
#
# Installation Option 2: WSL2 + QEMU
#   wsl --install
#   wsl sudo apt install qemu-system-x86 qemu-utils qemu-kvm
#
# Usage:
#   .\test-vm-config-windows.ps1 create    - Create a new test VM disk
#   .\test-vm-config-windows.ps1 boot-iso  - Boot from Ubuntu ISO for installation
#   .\test-vm-config-windows.ps1 boot      - Boot the installed system
#   .\test-vm-config-windows.ps1 snapshot  - Create a snapshot of current state
#   .\test-vm-config-windows.ps1 restore   - Restore from latest snapshot
#   .\test-vm-config-windows.ps1 clean     - Remove all VM files
#

param(
    [Parameter(Position=0)]
    [ValidateSet('create', 'boot-iso', 'boot', 'headless', 'snapshot', 'restore', 'clean', 'help')]
    [string]$Command = 'help'
)

# Configuration
$VM_DIR = "$env:USERPROFILE\ghost-ai-test-vm"
$VM_DISK = "$VM_DIR\ghost-ai-test.qcow2"
$VM_SNAPSHOT = "$VM_DIR\ghost-ai-snapshot.qcow2"
$DISK_SIZE = "256G"
$RAM_SIZE = "8G"
$CPU_CORES = "4"
$UBUNTU_ISO = "$VM_DIR\ubuntu-24.04-desktop-amd64.iso"
$UBUNTU_ISO_URL = "https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso"

# QEMU paths to check
$QEMU_PATHS = @(
    "C:\Program Files\qemu\qemu-system-x86_64.exe",
    "C:\Program Files (x86)\qemu\qemu-system-x86_64.exe",
    "$env:ProgramFiles\qemu\qemu-system-x86_64.exe",
    "qemu-system-x86_64.exe"  # In PATH
)

# Colors for output
function Write-Log {
    param([string]$Message)
    Write-Host "[VM] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[VM] ✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[VM] ✗ $Message" -ForegroundColor Red
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[VM] ⚠ $Message" -ForegroundColor Yellow
}

# Find QEMU installation
function Find-QEMU {
    foreach ($path in $QEMU_PATHS) {
        if (Test-Path $path -PathType Leaf) {
            return $path
        }
        # Try as command
        if (Get-Command $path -ErrorAction SilentlyContinue) {
            return $path
        }
    }
    return $null
}

# Check dependencies
function Check-Dependencies {
    $qemu = Find-QEMU

    if (-not $qemu) {
        Write-Error-Custom "QEMU not found!"
        Write-Host ""
        Write-Host "Installation options:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Option 1: QEMU for Windows (Recommended)" -ForegroundColor Cyan
        Write-Host "  1. Download: https://qemu.weilnetz.de/w64/" -ForegroundColor White
        Write-Host "  2. Install to C:\Program Files\qemu" -ForegroundColor White
        Write-Host "  3. Add to PATH in System Environment Variables" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 2: WSL2 + Ubuntu + QEMU" -ForegroundColor Cyan
        Write-Host "  wsl --install" -ForegroundColor White
        Write-Host "  wsl sudo apt install qemu-system-x86 qemu-utils" -ForegroundColor White
        Write-Host ""
        Write-Host "Option 3: Use Hyper-V (Windows Pro/Enterprise)" -ForegroundColor Cyan
        Write-Host "  Use Windows built-in Hyper-V Manager" -ForegroundColor White
        Write-Host ""
        exit 1
    }

    return $qemu
}

# Create VM
function Create-VM {
    $qemu = Check-Dependencies
    $qemu_img = $qemu -replace "qemu-system-x86_64.exe", "qemu-img.exe"

    if (-not (Test-Path $VM_DIR)) {
        New-Item -ItemType Directory -Path $VM_DIR | Out-Null
    }

    if (Test-Path $VM_DISK) {
        Write-Warning-Custom "VM disk already exists: $VM_DISK"
        $response = Read-Host "Delete and recreate? (y/n)"
        if ($response -ne 'y') {
            exit 0
        }
        Remove-Item $VM_DISK
    }

    Write-Log "Creating VM disk ($DISK_SIZE)..."
    & $qemu_img create -f qcow2 $VM_DISK $DISK_SIZE
    Write-Success "VM disk created: $VM_DISK"

    # Download Ubuntu ISO if not present
    if (-not (Test-Path $UBUNTU_ISO)) {
        Write-Log "Ubuntu ISO not found. Downloading (~6GB)..."
        Write-Warning-Custom "This may take a while..."

        try {
            # Use .NET WebClient for download with progress
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($UBUNTU_ISO_URL, $UBUNTU_ISO)
            Write-Success "Ubuntu ISO downloaded"
        } catch {
            Write-Error-Custom "Failed to download Ubuntu ISO"
            Write-Host "You can download manually from: $UBUNTU_ISO_URL"
            Write-Host "Save to: $UBUNTU_ISO"
            exit 1
        }
    }

    Write-Host ""
    Write-Success "VM created successfully!"
    Write-Host ""
    Write-Log "Next: Run '.\test-vm-config-windows.ps1 boot-iso' to install Ubuntu"
}

# Boot from ISO
function Boot-ISO {
    $qemu = Check-Dependencies

    if (-not (Test-Path $VM_DISK)) {
        Write-Error-Custom "VM disk not found. Run '.\test-vm-config-windows.ps1 create' first"
        exit 1
    }

    if (-not (Test-Path $UBUNTU_ISO)) {
        Write-Error-Custom "Ubuntu ISO not found at: $UBUNTU_ISO"
        Write-Log "Download it or run '.\test-vm-config-windows.ps1 create'"
        exit 1
    }

    Write-Log "Booting VM from Ubuntu ISO..."
    Write-Log "RAM: $RAM_SIZE, CPUs: $CPU_CORES"
    Write-Host ""
    Write-Host "=== INSTALLATION INSTRUCTIONS ===" -ForegroundColor Yellow
    Write-Host "1. Select 'Install Ubuntu' when prompted"
    Write-Host "2. Choose 'Erase disk and install Ubuntu'"
    Write-Host "3. Create user 'ghost' with your chosen password"
    Write-Host "4. After installation, shutdown and run '.\test-vm-config-windows.ps1 boot'"
    Write-Host "=================================" -ForegroundColor Yellow
    Write-Host ""

    & $qemu `
        -m $RAM_SIZE `
        -smp $CPU_CORES `
        -drive file=$VM_DISK,format=qcow2 `
        -cdrom $UBUNTU_ISO `
        -boot d `
        -vga virtio `
        -display sdl `
        -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080,hostfwd=tcp::8188-:8188,hostfwd=tcp::11434-:11434 `
        -device virtio-net-pci,netdev=net0
}

# Boot installed system
function Boot-VM {
    $qemu = Check-Dependencies

    if (-not (Test-Path $VM_DISK)) {
        Write-Error-Custom "VM disk not found. Run '.\test-vm-config-windows.ps1 create' first"
        exit 1
    }

    Write-Log "Booting Ghost AI test VM..."
    Write-Log "RAM: $RAM_SIZE, CPUs: $CPU_CORES"
    Write-Host ""
    Write-Host "Port forwarding:" -ForegroundColor Cyan
    Write-Host "  SSH:     localhost:2222  -> VM:22"
    Write-Host "  Kiwix:   localhost:8080  -> VM:8080"
    Write-Host "  ComfyUI: localhost:8188  -> VM:8188"
    Write-Host "  Ollama:  localhost:11434 -> VM:11434"
    Write-Host ""
    Write-Log "To SSH into VM: ssh -p 2222 ghost@localhost"
    Write-Host ""

    & $qemu `
        -m $RAM_SIZE `
        -smp $CPU_CORES `
        -drive file=$VM_DISK,format=qcow2 `
        -vga virtio `
        -display sdl `
        -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080,hostfwd=tcp::8188-:8188,hostfwd=tcp::11434-:11434 `
        -device virtio-net-pci,netdev=net0
}

# Create snapshot
function Create-Snapshot {
    Check-Dependencies | Out-Null

    if (-not (Test-Path $VM_DISK)) {
        Write-Error-Custom "VM disk not found"
        exit 1
    }

    Write-Log "Creating snapshot..."
    Copy-Item $VM_DISK $VM_SNAPSHOT
    Write-Success "Snapshot created: $VM_SNAPSHOT"
}

# Restore snapshot
function Restore-Snapshot {
    if (-not (Test-Path $VM_SNAPSHOT)) {
        Write-Error-Custom "No snapshot found"
        exit 1
    }

    Write-Log "Restoring from snapshot..."
    Copy-Item $VM_SNAPSHOT $VM_DISK -Force
    Write-Success "VM restored from snapshot"
}

# Headless mode
function Boot-Headless {
    $qemu = Check-Dependencies

    if (-not (Test-Path $VM_DISK)) {
        Write-Error-Custom "VM disk not found"
        exit 1
    }

    Write-Log "Booting in headless mode..."
    Write-Log "Connect via SSH: ssh -p 2222 ghost@localhost"
    Write-Log "Or VNC: localhost:5900"

    Start-Process -FilePath $qemu -ArgumentList `
        "-m", $RAM_SIZE, `
        "-smp", $CPU_CORES, `
        "-drive", "file=$VM_DISK,format=qcow2", `
        "-nographic", `
        "-vnc", ":0", `
        "-netdev", "user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080,hostfwd=tcp::8188-:8188,hostfwd=tcp::11434-:11434", `
        "-device", "virtio-net-pci,netdev=net0" `
        -WindowStyle Hidden

    Write-Success "VM started in background"
}

# Clean up
function Clean-VM {
    Write-Warning-Custom "This will delete all VM files!"
    $response = Read-Host "Continue? (y/n)"
    if ($response -eq 'y') {
        Remove-Item -Recurse -Force $VM_DIR
        Write-Success "VM files cleaned"
    }
}

# Show usage
function Show-Usage {
    Write-Host "Ghost AI System - VM Test Configuration (Windows)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "⚠️  PLATFORM: Windows only (use test-vm-config-linux.sh for Linux)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Usage: .\test-vm-config-windows.ps1 <command>"
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Green
    Write-Host "  create      Create a new test VM disk and download Ubuntu ISO"
    Write-Host "  boot-iso    Boot from Ubuntu ISO (for initial installation)"
    Write-Host "  boot        Boot the installed system"
    Write-Host "  headless    Boot in headless mode (SSH/VNC access)"
    Write-Host "  snapshot    Create a snapshot of current VM state"
    Write-Host "  restore     Restore VM from latest snapshot"
    Write-Host "  clean       Remove all VM files"
    Write-Host ""
    Write-Host "Prerequisites:" -ForegroundColor Yellow
    Write-Host "  Download QEMU: https://qemu.weilnetz.de/w64/"
    Write-Host "  Or use WSL2: wsl --install && wsl sudo apt install qemu-system-x86"
    Write-Host ""
    Write-Host "Typical workflow:" -ForegroundColor Cyan
    Write-Host "  1. .\test-vm-config-windows.ps1 create      # Create VM and download Ubuntu"
    Write-Host "  2. .\test-vm-config-windows.ps1 boot-iso    # Install Ubuntu (create 'ghost' user)"
    Write-Host "  3. .\test-vm-config-windows.ps1 boot        # Boot installed system"
    Write-Host "  4. Copy orchestrator.sh to VM and run it"
    Write-Host "  5. .\test-vm-config-windows.ps1 snapshot    # Save working state"
    Write-Host ""
}

# Main execution
switch ($Command) {
    'create'    { Create-VM }
    'boot-iso'  { Boot-ISO }
    'boot'      { Boot-VM }
    'headless'  { Boot-Headless }
    'snapshot'  { Create-Snapshot }
    'restore'   { Restore-Snapshot }
    'clean'     { Clean-VM }
    default     { Show-Usage }
}
