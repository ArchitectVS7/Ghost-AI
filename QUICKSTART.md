# Ghost AI - Quick Start Guide

## 🚀 New Unified Installer (Recommended)

We now support **automatic hardware detection** and **both ARM64 and x86_64 architectures**!

### Installation (One Command)

```bash
# Clone repository
git clone <your-repo-url>
cd Ghost-AI

# Run unified installer
sudo ./install.sh
```

The installer will:
1. ✅ Auto-detect your hardware (CPU, RAM, GPU)
2. ✅ Show you the detected configuration
3. ✅ Let you choose AUTO or MANUAL installation
4. ✅ Run the appropriate orchestrator for your system

---

## 📋 What's New

### Hardware Detection
- **Automatic CPU architecture detection** (ARM64 vs x86_64)
- **RAM-based model selection** (3B to 70B models)
- **GPU detection** (NVIDIA, AMD, Apple Silicon, CPU-only)
- **Disk space validation**

### Architecture Support

#### **ARM64 (Apple Silicon)**
- ✅ Optimized for M1/M2/M3/M4 Macs
- ✅ Metal acceleration support
- ✅ ARM-native Ollama and models
- ✅ Efficient model selection (3B-14B models)
- ✅ Optional Desktop GUI
- ❌ No CUDA/NVIDIA (not applicable)
- ❌ No 70B models (unless RAM > 32GB)

#### **x86_64 (Intel/AMD)**
- ✅ Full NVIDIA GPU support with CUDA
- ✅ AMD GPU support
- ✅ Complete model range (3B-70B)
- ✅ ComfyUI with GPU acceleration
- ✅ Traditional bootable USB creation

---

## 🎯 Installation Options

### Option 1: Auto-Install (Recommended)
```bash
sudo ./install.sh
# Select option 1 (AUTO)
```

### Option 2: Manual Architecture Selection
```bash
sudo ./install.sh
# Select option 2 (MANUAL)
# Choose your architecture
```

### Option 3: Direct Orchestrator (Advanced)
```bash
# For ARM64
sudo ./orchestrator-arm64.sh

# For x86_64
sudo ./orchestrator-x86.sh
```

---

## 💾 RAM-Based Model Selection

The installer automatically selects models based on your RAM:

| RAM | Tier | Models Included |
|-----|------|----------------|
| < 8GB | Minimal | llama3.2:3b only |
| 8-16GB | Basic | 3B, phi3:mini, codestral |
| 16-32GB | Standard | All basic + llama3.1:8b, mistral:7b |
| 32GB+ | Performance | All standard + vision, qwen2.5:14b |

---

## 🖥️ VM Testing (Current Setup)

You're currently in an **ARM64 Ubuntu VM**. To test:

```bash
# Inside VM
sudo apt update
sudo apt install git

# Clone repo
git clone <your-repo-url>
cd Ghost-AI

# Run installer
sudo ./install.sh
```

**For Desktop GUI (optional):**
```bash
# After base installation
sudo apt install ubuntu-desktop
sudo reboot
```

---

## 📊 What Gets Installed

### Core Components (All Architectures)
- ✅ Ollama (LLM engine)
- ✅ AI Models (based on RAM)
- ✅ OpenClaw (AI assistant)
- ✅ Whisper (speech-to-text)
- ✅ Piper TTS (text-to-speech)
- ✅ Network isolation tools
- ✅ Security hardening

### Architecture-Specific

**ARM64 Only:**
- Metal acceleration
- Lightweight models
- Optional desktop

**x86_64 Only:**
- NVIDIA CUDA (if GPU detected)
- ComfyUI + Stable Diffusion
- Full model range

---

## 🔧 Customization

### Environment Variables
```bash
# Custom tier
sudo PERF_TIER=standard ./install.sh

# Skip optional components
sudo INSTALL_WIKIPEDIA=false ./install.sh

# Enable ComfyUI on ARM64
sudo INSTALL_COMFYUI=true ./orchestrator-arm64.sh
```

### Config File (Advanced)
```json
{
  "tier": "standard",
  "options": {
    "wikipedia": false,
    "desktop": true,
    "comfyui": false
  }
}
```

```bash
sudo ./install.sh config.json
```

---

## 📝 Files Created

- `detect-hardware.sh` - Hardware detection
- `install.sh` - Main installer (entry point)
- `orchestrator-arm64.sh` - ARM64 setup
- `orchestrator-x86.sh` - x86_64 setup
- `orchestrator.sh` - Original (kept for compatibility)

---

## ⏱️ Installation Time

- **Basic tier**: 1-2 hours (mostly downloads)
- **Standard tier**: 2-3 hours
- **Performance tier**: 3-4 hours
- **+ Wikipedia**: +1-2 hours

---

## 🆘 Troubleshooting

### Wrong Architecture Detected
```bash
# Use manual selection
sudo ./install.sh
# Choose option 2
```

### Low RAM Warning
The installer will automatically select appropriate models for your RAM.

### Disk Space Issues
```bash
# Check space
df -h /

# Skip optional components
sudo INSTALL_WIKIPEDIA=false ./install.sh
```

---

## 📚 More Documentation

- `README.md` - Full documentation
- `VM-TESTING.md` - VM testing guide
- `setup-guide.md` - Detailed setup instructions

---

## 🎉 Quick Test After Installation

```bash
# Test Ollama
ollama list
ollama run llama3.2:3b "Hello!"

# Check system info
~/system-info.sh

# Run full test suite
~/test-system.sh
```

---

**Ready to install? Run:** `sudo ./install.sh`
