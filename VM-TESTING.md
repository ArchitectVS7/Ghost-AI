# Ghost AI System - Virtual Machine Testing Guide

This guide explains how to test the Ghost AI installation in a virtual machine before deploying to real hardware.

**✨ NEW: Now supports both ARM64 (Apple Silicon) and x86_64 (Intel/AMD) architectures with automatic detection!**

## 🚀 Quick VM Testing (New Method)

After setting up a VM with Ubuntu, simply run:

```bash
# Inside the VM
sudo apt update && sudo apt install git -y
git clone <your-repo-url>
cd Ghost-AI
sudo ./install.sh
```

The installer will:
- Auto-detect your VM's architecture (ARM64 or x86_64)
- Detect RAM and select appropriate models
- Install the optimized stack for your system

**See platform-specific setup below for VM creation.**

---

## Why Test in a VM?

✅ **Safety** - No risk of data loss on real hardware
✅ **Speed** - Test and iterate quickly
✅ **Snapshots** - Save progress and rollback anytime
✅ **Debugging** - Easy to troubleshoot issues
✅ **Verification** - Ensure everything works before USB deployment

## Platform-Specific Scripts

We provide three separate scripts, one for each major platform:

| Platform | Script | Package Manager | Hypervisor |
|----------|--------|----------------|------------|
| **Linux** | `test-vm-config-linux.sh` | apt/dnf/pacman | QEMU/KVM |
| **macOS** | `test-vm-config-macos.sh` | Homebrew | QEMU + HVF |
| **Windows** | `test-vm-config-windows.ps1` | Manual/WSL2 | QEMU |

⚠️ **Important:** Use the script for YOUR platform. They are NOT interchangeable.

---

## Linux Setup

### Prerequisites
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install qemu-system-x86 qemu-utils qemu-kvm

# Fedora
sudo dnf install qemu-kvm qemu-img

# Arch
sudo pacman -S qemu qemu-arch-extra
```

### Requirements
- ~300GB free disk space
- 8GB+ RAM (16GB recommended)
- CPU with virtualization support (check: `egrep -c '(vmx|svm)' /proc/cpuinfo`)

### Usage
```bash
# 1. Create VM and download Ubuntu ISO
./test-vm-config-linux.sh create

# 2. Boot from ISO and install Ubuntu
./test-vm-config-linux.sh boot-iso
# Follow on-screen instructions to install Ubuntu
# Create user: ghost
# After installation, shutdown the VM

# 3. Boot the installed system
./test-vm-config-linux.sh boot

# 4. SSH into the VM (from host)
ssh -p 2222 ghost@localhost

# 5. Inside VM, run the orchestrator
cd /path/to/scripts
sudo bash ghost-ai-orchestrator.sh

# 6. Create a snapshot after successful setup
./test-vm-config-linux.sh snapshot

# 7. Restore from snapshot if needed
./test-vm-config-linux.sh restore

# 8. Clean up when done
./test-vm-config-linux.sh clean
```

### Troubleshooting
- **KVM not available:** Check virtualization is enabled in BIOS
- **Permission denied:** Add user to `kvm` group: `sudo usermod -aG kvm $USER`
- **Slow performance:** Ensure KVM is working: `kvm-ok` command

---

## macOS Setup

### Prerequisites
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install QEMU
brew install qemu
```

### Requirements
- macOS 10.15+ (Intel or Apple Silicon)
- ~300GB free disk space
- 8GB+ RAM (16GB recommended)
- Xcode Command Line Tools (install: `xcode-select --install`)

### Usage
```bash
# 1. Create VM and download Ubuntu ISO
./test-vm-config-macos.sh create

# 2. Boot from ISO and install Ubuntu
./test-vm-config-macos.sh boot-iso
# Follow on-screen instructions
# Create user: ghost
# After installation, shutdown

# 3. Boot the installed system
./test-vm-config-macos.sh boot

# 4. SSH into the VM (from host)
ssh -p 2222 ghost@localhost

# 5. Inside VM, run the orchestrator
cd /path/to/scripts
sudo bash ghost-ai-orchestrator.sh

# 6. Create a snapshot
./test-vm-config-macos.sh snapshot

# 7. Restore if needed
./test-vm-config-macos.sh restore

# 8. Clean up
./test-vm-config-macos.sh clean
```

### Troubleshooting
- **Homebrew not in PATH:** Run `eval "$(/opt/homebrew/bin/brew shellenv)"`
- **Slow performance:** This is normal - QEMU on macOS doesn't have full hardware acceleration
- **Display issues:** Try adding `-display gtk` flag manually
- **Apple Silicon notes:** x86_64 emulation will be slower than native

---

## Windows Setup

### Prerequisites

**Option 1: QEMU for Windows (Recommended)**
1. Download QEMU installer: https://qemu.weilnetz.de/w64/
2. Install to `C:\Program Files\qemu`
3. Add to System PATH:
   - Right-click "This PC" → Properties
   - Advanced system settings → Environment Variables
   - Edit "Path" → Add `C:\Program Files\qemu`

**Option 2: WSL2 + QEMU**
```powershell
# Install WSL2
wsl --install

# Inside WSL2
wsl
sudo apt update
sudo apt install qemu-system-x86 qemu-utils
```

### Requirements
- Windows 10/11 (Pro, Enterprise, or Home with WSL2)
- ~300GB free disk space
- 8GB+ RAM (16GB recommended)
- CPU with virtualization support (Intel VT-x or AMD-V)
- Enable virtualization in BIOS

### Usage
```powershell
# Run in PowerShell (Run as Administrator)

# 1. Create VM and download Ubuntu ISO
.\test-vm-config-windows.ps1 create

# 2. Boot from ISO and install Ubuntu
.\test-vm-config-windows.ps1 boot-iso
# Follow on-screen instructions
# Create user: ghost
# After installation, shutdown

# 3. Boot the installed system
.\test-vm-config-windows.ps1 boot

# 4. SSH into the VM (from host)
ssh -p 2222 ghost@localhost
# Or use PuTTY: localhost:2222

# 5. Inside VM, run the orchestrator
cd /path/to/scripts
sudo bash ghost-ai-orchestrator.sh

# 6. Create a snapshot
.\test-vm-config-windows.ps1 snapshot

# 7. Restore if needed
.\test-vm-config-windows.ps1 restore

# 8. Clean up
.\test-vm-config-windows.ps1 clean
```

### Troubleshooting
- **Execution policy error:** Run `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **QEMU not found:** Ensure QEMU is in System PATH
- **Hyper-V conflicts:** Disable Hyper-V or use it instead: `bcdedit /set hypervisorlaunchtype off`
- **SSH not working:** Install OpenSSH client via Windows Settings → Apps → Optional Features

---

## Common Workflow (All Platforms)

### Initial Setup
1. Run the `create` command to download Ubuntu ISO and create virtual disk
2. Run `boot-iso` to boot from ISO and install Ubuntu
3. During installation:
   - Select "Install Ubuntu"
   - Choose "Erase disk and install Ubuntu" (this is the VM disk, safe to erase)
   - Create user `ghost` with a password you'll remember
   - Wait for installation to complete
   - Shutdown the VM
4. Run `boot` to start the installed system

### Testing the Orchestrator
1. SSH into the VM: `ssh -p 2222 ghost@localhost`
2. Transfer the orchestrator script to the VM:
   ```bash
   # From host machine
   scp -P 2222 ghost-ai-orchestrator.sh ghost@localhost:/home/ghost/
   ```
3. Inside the VM, run the orchestrator:
   ```bash
   cd /home/ghost
   sudo bash ghost-ai-orchestrator.sh
   ```
4. Wait for completion (2-4 hours)
5. Test all features

### Using Snapshots
Snapshots save the entire VM state. Use them to:
- Save progress before risky changes
- Create checkpoints at major milestones
- Quick rollback if something breaks

```bash
# Create snapshot before testing
./test-vm-config-<platform>.sh snapshot

# Make changes, test features...

# If something breaks, restore
./test-vm-config-<platform>.sh restore
```

### Accessing Services from Host

All VM scripts forward these ports automatically:

| Service | VM Port | Host Access |
|---------|---------|-------------|
| SSH | 22 | `ssh -p 2222 ghost@localhost` |
| Ollama API | 11434 | `http://localhost:11434` |
| ComfyUI | 8188 | `http://localhost:8188` |
| Kiwix | 8080 | `http://localhost:8080` |

**Examples:**
```bash
# Test Ollama from host
curl http://localhost:11434/api/tags

# Access ComfyUI web interface
# Open browser: http://localhost:8188

# Browse Wikipedia
# Open browser: http://localhost:8080
```

---

## Performance Tips

### Allocate More Resources
Edit the script variables at the top:
```bash
RAM_SIZE="16G"     # Default: 8G
CPU_CORES="8"      # Default: 4
DISK_SIZE="512G"   # Default: 256G
```

### Use Headless Mode
For better performance without GUI:
```bash
./test-vm-config-<platform>.sh headless
# Connect via SSH or VNC
```

### Speed Up Downloads
Pre-download large files before running orchestrator:
1. Download models on host machine
2. Transfer to VM via SCP
3. Skip download steps in orchestrator

---

## File Locations

### VM Files
All VM files are stored in:
- **Linux/macOS:** `~/ghost-ai-test-vm/`
- **Windows:** `C:\Users\<YourName>\ghost-ai-test-vm\`

**Contents:**
- `ghost-ai-test.qcow2` - VM disk (grows to ~200GB after installation)
- `ghost-ai-snapshot.qcow2` - Snapshot backup
- `ubuntu-24.04-desktop-amd64.iso` - Ubuntu installer (~6GB)

### Space Requirements
- Empty VM: ~1GB
- After Ubuntu install: ~10GB
- After full Ghost AI setup: ~150-250GB (depending on models)
- Snapshot: Same size as VM disk

---

## Advanced Usage

### Multiple VMs
Test different configurations in parallel:
```bash
# Edit script to use different VM_DIR
VM_DIR="$HOME/ghost-ai-test-vm-minimal"
VM_DIR="$HOME/ghost-ai-test-vm-full"
```

### Custom Networking
Edit the `-netdev` line in the script to forward additional ports:
```bash
-netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::3000-:3000
```

### Increase Disk Size
If you run out of space:
```bash
# Stop the VM first
qemu-img resize ghost-ai-test.qcow2 +100G

# Boot VM and resize partition
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1
```

---

## Comparing VM to Real USB

### What's Different
- **Performance:** VM is slower (no GPU acceleration)
- **Persistence:** VM stored on host disk, not USB
- **Portability:** VM not portable like USB

### What's the Same
- All software and configurations
- All AI models and features
- Network isolation capabilities
- Security settings

### After VM Testing
Once you've verified everything works in the VM:

1. Create a snapshot of the working VM
2. Write to real USB using `preflight.sh`
3. Boot from USB and run orchestrator
4. Compare results with VM

---

## Cleanup

### Remove Everything
```bash
# All platforms
./test-vm-config-<platform>.sh clean
```

This removes:
- VM disk
- Snapshots
- Ubuntu ISO
- All test data

### Keep ISO for Future Tests
```bash
# Manually delete just the VM files
rm ~/ghost-ai-test-vm/ghost-ai-test.qcow2
rm ~/ghost-ai-test-vm/ghost-ai-snapshot.qcow2
# Keep ubuntu-24.04-desktop-amd64.iso
```

---

## FAQ

**Q: Which platform script should I use?**
A: Use the one that matches your host OS. Don't use the Linux script on macOS, etc.

**Q: Can I run the VM headless/without GUI?**
A: Yes, use the `headless` command and connect via SSH or VNC.

**Q: How much disk space do I really need?**
A: Minimum 150GB, recommended 300GB for full installation with all models.

**Q: The VM is very slow, is this normal?**
A: Some slowness is expected, especially on macOS. Ensure virtualization is enabled in BIOS (Linux/Windows).

**Q: Can I transfer the VM to a USB drive?**
A: Not directly. Use the VM to test, then create a real USB with the preflight script.

**Q: I get "permission denied" errors.**
A: On Linux, add yourself to the `kvm` group. On Windows, run PowerShell as Administrator.

**Q: SSH connection refused.**
A: Install OpenSSH server in the VM: `sudo apt install openssh-server`

**Q: Can I use VirtualBox or VMware instead?**
A: Yes, but you'll need to set up the VM manually. The scripts only support QEMU.

---

## Support

If you encounter issues:

1. Check the script output for error messages
2. Verify all prerequisites are installed
3. Check virtualization is enabled in BIOS
4. Try the headless mode if GUI has issues
5. Review the troubleshooting section for your platform

---

**Next Steps:**
After successful VM testing, proceed to create a real USB drive using the preflight script. See [README.md](README.md) for USB creation instructions.
