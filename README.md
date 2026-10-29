# archflutter

Gigachad Flutter development setup for Arch Linux. **No Android Studio required.**

- CLI-only Android SDK (sdkmanager, avdmanager)
- KVM-accelerated Android emulator. Skip it with `--no-emulator` to debug on a phone over USB.
- Flutter stable via git
- Neovim (LazyVim) integration with flutter-tools.nvim
- Makefile workflow commands

## Quick start

```bash
# Clone
git clone https://github.com/VitorFOG/archflutter.git
cd archflutter

# Run setup (requires sudo for pacman)
./setup.sh

# Reboot so the kvm and libvirt group changes apply
sudo reboot

# Verify
flutter doctor
```

### Physical device only

`--no-emulator` skips KVM, the emulator, the system image and the AVD:

```bash
./setup.sh --no-emulator
source ~/.zshrc

# Enable USB debugging on the phone, plug it in, then:
adb devices
flutter devices
```

This mode needs no reboot. To add the emulator later, run `./setup.sh` again without the flag.

## What gets installed

| Component | Location |
|-----------|----------|
| Android SDK | `~/Android/Sdk` |
| Flutter SDK | `~/.local/flutter` |
| AVD `pixel_api34`\* | `~/.android/avd/` |

**System packages:** `jdk17-openjdk`, `android-tools`, `android-udev`, `libvirt`\*, `qemu-full`\*, `dnsmasq`\*, `bridge-utils`\*

**SDK components:** `platform-tools`, `emulator`\*, `platforms;android-36`, `build-tools;36.0.0`, `system-images;android-34;google_apis;x86_64`\*

\* `--no-emulator` skips these.

If your pacman repos don't have a package, such as `bridge-utils`, the script prints a warning and skips it.

## VS Code

The setup works with any editor. For VS Code, install the Flutter extension. It installs the Dart extension too.

```bash
code --install-extension Dart-Code.flutter
```

The extension looks for `flutter` on your `PATH`. A desktop launcher can start VS Code without reading `~/.zshrc`. If the extension can't find the SDK, set `dart.flutterSdkPath` to the absolute path of `~/.local/flutter`, for example `/home/you/.local/flutter`.

## Neovim setup

Copy the Flutter plugin config to your LazyVim setup:

```bash
cp nvim/flutter.lua ~/.config/nvim/lua/plugins/
```

Then open Neovim and run `:Lazy` to install plugins.

**Keymaps** in `.dart` files:

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

## Makefile workflow

Copy `Makefile` to your Flutter project root:

```bash
cp Makefile ~/your-flutter-project/
```

```bash
make emu       # Launch emulator
make devices   # flutter devices
make run       # flutter run
make test      # flutter test
make analyze   # flutter analyze
make fmt       # dart format .
make clean     # flutter clean
make doctor    # flutter doctor -v
make check     # fmt + analyze + test
```

## Daily workflow

```bash
# Start the emulator, or plug in your phone instead
make emu

# Development loop
make run
# Edit code in your editor
# Press 'r' for hot reload
# Press 'R' for hot restart
```

## Requirements

- Arch Linux or an Arch-based distro
- For the emulator, a CPU with virtualization (Intel VT-x or AMD-V)
- About 10 GB of disk space for the full install

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

If `/dev/kvm` isn't writable, reboot or log out and back in so the group changes apply.

**Emulator won't start or runs slowly?**
The x86_64 system image needs KVM. Run the KVM checks above.

**Phone missing from `adb devices`?**
If `adb devices` lists the phone as `unauthorized`, unlock it and accept the "Allow USB debugging?" prompt. If it lists `no permissions`, unplug the phone and plug it back in so the `android-udev` rules apply.

**flutter doctor issues?**
```bash
flutter doctor -v  # Verbose output
flutter config --android-sdk ~/Android/Sdk
```

## License

MIT
