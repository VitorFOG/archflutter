# archflutter

Gigachad Flutter development setup for Arch Linux. **No Android Studio required.**

- CLI-only Android SDK (sdkmanager, avdmanager, emulator)
- KVM-accelerated emulator
- Flutter stable via git
- Neovim (LazyVim) integration with flutter-tools.nvim
- Makefile workflow commands

## Quick Start

```bash
# Clone
git clone https://github.com/YOUR_USERNAME/archflutter.git
cd archflutter

# Run setup (requires sudo for pacman)
./setup.sh

# Reboot (required for KVM group permissions)
sudo reboot

# Verify
flutter doctor
```

## What Gets Installed

| Component | Location |
|-----------|----------|
| Android SDK | `~/Android/Sdk` |
| Flutter SDK | `~/.local/flutter` |
| AVD (pixel_api34) | `~/.android/avd/` |

**System packages:** `jdk17-openjdk`, `android-tools`, `android-udev`, `libvirt`, `qemu-full`, `dnsmasq`, `bridge-utils`

**SDK components:** `platform-tools`, `emulator`, `platforms;android-36`, `build-tools;36.0.0`, `system-images;android-34;google_apis;x86_64`

## Neovim Setup

Copy the Flutter plugin config to your LazyVim setup:

```bash
cp nvim/flutter.lua ~/.config/nvim/lua/plugins/
```

Then open Neovim and run `:Lazy` to install plugins.

**Keymaps** (in `.dart` files):

| Key | Action |
|-----|--------|
| `<leader>Fs` | Flutter Run |
| `<leader>Fr` | Hot Reload |
| `<leader>FR` | Hot Restart |
| `<leader>Fq` | Quit |
| `<leader>Fd` | Devices |
| `<leader>Fe` | Emulators |
| `<leader>Fo` | Widget Outline |
| `<leader>Fp` | Pub Get |

## Workflow (Makefile)

Copy `Makefile` to your Flutter project root:

```bash
cp Makefile ~/your-flutter-project/
```

```bash
make emu       # Launch emulator
make run       # flutter run
make test      # flutter test
make analyze   # flutter analyze
make fmt       # dart format .
make clean     # flutter clean
make doctor    # flutter doctor -v
make check     # fmt + analyze + test
```

## Daily Workflow

```bash
# Start of day
make emu

# Development loop
make run
# Edit code in Neovim
# Press 'r' for hot reload
# Press 'R' for hot restart
```

## Requirements

- Arch Linux (or Arch-based distro)
- CPU with virtualization (Intel VT-x or AMD-V)
- ~10GB disk space

## Troubleshooting

**KVM not working?**
```bash
# Check virtualization support
grep -E 'vmx|svm' /proc/cpuinfo

# Check KVM module
lsmod | grep kvm

# Check permissions
ls -la /dev/kvm
groups | grep kvm
```

If `/dev/kvm` isn't writable, reboot or re-login for group changes.

**Emulator slow?**
Ensure KVM is working. Without it, emulator uses software rendering.

**flutter doctor issues?**
```bash
flutter doctor -v  # Verbose output
flutter config --android-sdk ~/Android/Sdk
```

## License

MIT
