#!/bin/bash
# Flutter Mobile Dev Environment Setup for Arch Linux
# Idempotent - safe to rerun
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err() { echo -e "${RED}[x]${NC} $1"; }

ANDROID_SDK_ROOT="$HOME/Android/Sdk"
FLUTTER_ROOT="$HOME/.local/flutter"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip"
CMDLINE_TOOLS_SHA256="7ec965280a073311c339e571cd5de778b9975026cfcbe79f2b1cdcb1e15317ee"

# ============================================================
# STEP 1: System Dependencies
# ============================================================
step1_system_deps() {
    log "Installing system dependencies via pacman..."
    sudo pacman -S --needed --noconfirm \
        git curl unzip zip \
        base-devel clang cmake ninja \
        ripgrep fd fzf \
        jdk17-openjdk \
        android-tools android-udev \
        libvirt qemu-full dnsmasq bridge-utils

    # Set JAVA_HOME for JDK 17
    if ! grep -q "JAVA_HOME.*java-17-openjdk" ~/.zshrc 2>/dev/null; then
        log "Adding JAVA_HOME to .zshrc..."
        cat >> ~/.zshrc << 'EOF'

# Java 17 (for Android SDK)
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
EOF
    else
        warn "JAVA_HOME already configured in .zshrc"
    fi

    log "System dependencies installed."
}

# ============================================================
# STEP 2: KVM/Libvirt Configuration
# ============================================================
step2_kvm_setup() {
    log "Configuring KVM/libvirt for hardware acceleration..."

    # Check virtualization support
    if grep -qE 'vmx|svm' /proc/cpuinfo; then
        log "CPU virtualization support detected."
    else
        err "No virtualization support detected in CPU. Emulator will be slow."
    fi

    # Check KVM modules
    if lsmod | grep -q kvm; then
        log "KVM modules loaded."
    else
        warn "KVM modules not loaded. Loading..."
        sudo modprobe kvm
        # AMD or Intel
        if grep -q 'svm' /proc/cpuinfo; then
            sudo modprobe kvm_amd
        else
            sudo modprobe kvm_intel
        fi
    fi

    # Enable libvirtd
    log "Enabling libvirtd service..."
    sudo systemctl enable --now libvirtd

    # Add user to groups
    GROUPS_NEEDED="libvirt kvm"
    RELOGIN_NEEDED=0
    for grp in $GROUPS_NEEDED; do
        if ! groups "$USER" | grep -qw "$grp"; then
            log "Adding $USER to $grp group..."
            sudo usermod -aG "$grp" "$USER"
            RELOGIN_NEEDED=1
        else
            warn "User already in $grp group."
        fi
    done

    # Check /dev/kvm permissions
    if [ -c /dev/kvm ]; then
        if [ -w /dev/kvm ]; then
            log "/dev/kvm is writable."
        else
            warn "/dev/kvm exists but not writable. May need re-login or udev rules."
        fi
    else
        err "/dev/kvm does not exist. KVM acceleration won't work."
    fi

    if [ "$RELOGIN_NEEDED" -eq 1 ]; then
        warn ">>> YOU MUST LOG OUT AND LOG BACK IN for group changes to take effect! <<<"
        warn ">>> After re-login, run this script again to continue setup. <<<"
    fi
}

# ============================================================
# STEP 3: Android SDK (CLI-only)
# ============================================================
step3_android_sdk() {
    log "Setting up Android SDK command-line tools..."

    mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"

    # Download if not present
    if [ ! -d "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin" ]; then
        log "Downloading Android command-line tools..."
        TMPZIP="/tmp/cmdline-tools.zip"
        curl -L -o "$TMPZIP" "$CMDLINE_TOOLS_URL"

        # Verify checksum
        log "Verifying checksum..."
        echo "$CMDLINE_TOOLS_SHA256  $TMPZIP" | sha256sum -c - || {
            err "Checksum mismatch! Aborting."
            exit 1
        }

        # Extract to temp, then move to correct location
        log "Extracting..."
        TMPDIR=$(mktemp -d)
        unzip -q "$TMPZIP" -d "$TMPDIR"
        rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
        mv "$TMPDIR/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
        rm -rf "$TMPDIR" "$TMPZIP"
        log "Command-line tools installed."
    else
        warn "Command-line tools already installed."
    fi

    # Add to PATH in .zshrc (idempotent)
    if ! grep -q "ANDROID_SDK_ROOT" ~/.zshrc 2>/dev/null; then
        log "Adding Android SDK paths to .zshrc..."
        cat >> ~/.zshrc << 'EOF'

# Android SDK
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
export PATH="$ANDROID_SDK_ROOT/emulator:$PATH"
EOF
    else
        warn "Android SDK paths already in .zshrc"
    fi

    # Export for current session
    export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
    export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
    export PATH="$ANDROID_SDK_ROOT/emulator:$PATH"
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

    log "Android SDK paths configured."
}

# ============================================================
# STEP 4: SDK Components via sdkmanager
# ============================================================
step4_sdk_components() {
    log "Installing SDK components via sdkmanager..."

    # Ensure sdkmanager is available
    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

    if ! command -v sdkmanager &>/dev/null; then
        err "sdkmanager not found. Run step 3 first."
        exit 1
    fi

    # Accept licenses
    log "Accepting Android SDK licenses..."
    yes | sdkmanager --licenses || true

    # Install components
    log "Installing platform-tools, emulator, platform, build-tools, system-image..."
    sdkmanager --install \
        "platform-tools" \
        "emulator" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "system-images;android-34;google_apis;x86_64"

    # Verify installations
    log "Verifying installations..."
    export PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"

    if command -v adb &>/dev/null; then
        log "adb: $(adb --version | head -1)"
    else
        err "adb not found in PATH"
    fi

    if command -v emulator &>/dev/null; then
        log "emulator: $(emulator -version 2>&1 | head -1)"
    else
        err "emulator not found in PATH"
    fi

    log "SDK components installed."
}

# ============================================================
# STEP 5: Create AVD
# ============================================================
step5_create_avd() {
    log "Creating AVD pixel_api34..."

    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/emulator:$PATH"
    export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
    export ANDROID_HOME="$ANDROID_SDK_ROOT"

    # Check if AVD already exists
    if avdmanager list avd 2>/dev/null | grep -q "pixel_api34"; then
        warn "AVD pixel_api34 already exists."
    else
        log "Creating pixel_api34 AVD..."
        echo "no" | avdmanager create avd \
            -n pixel_api34 \
            -k "system-images;android-34;google_apis;x86_64" \
            -d "pixel" \
            --force
        log "AVD created."
    fi

    # Configure AVD for better performance
    AVD_CONFIG="$HOME/.android/avd/pixel_api34.avd/config.ini"
    if [ -f "$AVD_CONFIG" ]; then
        log "Configuring AVD for optimal performance..."
        # Set RAM and heap (idempotent)
        grep -q "hw.ramSize" "$AVD_CONFIG" || echo "hw.ramSize=2048" >> "$AVD_CONFIG"
        grep -q "hw.gpu.enabled" "$AVD_CONFIG" || echo "hw.gpu.enabled=yes" >> "$AVD_CONFIG"
        grep -q "hw.gpu.mode" "$AVD_CONFIG" || echo "hw.gpu.mode=host" >> "$AVD_CONFIG"
    fi

    log "AVD configuration complete."
}

# ============================================================
# STEP 6: Flutter SDK
# ============================================================
step6_flutter() {
    log "Installing Flutter SDK..."

    if [ -d "$FLUTTER_ROOT" ] && [ -x "$FLUTTER_ROOT/bin/flutter" ]; then
        warn "Flutter already installed at $FLUTTER_ROOT"
        log "Updating Flutter..."
        "$FLUTTER_ROOT/bin/flutter" upgrade || true
    else
        log "Cloning Flutter stable..."
        rm -rf "$FLUTTER_ROOT"
        git clone https://github.com/flutter/flutter.git -b stable "$FLUTTER_ROOT"
    fi

    # Add to PATH in .zshrc (idempotent)
    if ! grep -q "FLUTTER_ROOT" ~/.zshrc 2>/dev/null; then
        log "Adding Flutter to .zshrc..."
        cat >> ~/.zshrc << 'EOF'

# Flutter SDK
export FLUTTER_ROOT="$HOME/.local/flutter"
export PATH="$FLUTTER_ROOT/bin:$PATH"
EOF
    else
        warn "Flutter paths already in .zshrc"
    fi

    # Export for current session
    export PATH="$FLUTTER_ROOT/bin:$PATH"

    # Pre-download Dart SDK
    log "Running flutter precache..."
    "$FLUTTER_ROOT/bin/flutter" precache

    # Configure Flutter to use our Android SDK
    log "Configuring Flutter Android SDK path..."
    "$FLUTTER_ROOT/bin/flutter" config --android-sdk "$ANDROID_SDK_ROOT"

    # Accept Android licenses through Flutter
    log "Accepting Android licenses through Flutter..."
    yes | "$FLUTTER_ROOT/bin/flutter" doctor --android-licenses || true

    log "Flutter installed."
}

# ============================================================
# STEP 7: Run flutter doctor
# ============================================================
step7_doctor() {
    log "Running flutter doctor..."
    export PATH="$FLUTTER_ROOT/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$PATH"
    export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

    "$FLUTTER_ROOT/bin/flutter" doctor -v
}

# ============================================================
# Main
# ============================================================
main() {
    echo "========================================"
    echo " Flutter Dev Setup for Arch Linux"
    echo " (No Android Studio)"
    echo "========================================"
    echo ""

    step1_system_deps
    step2_kvm_setup
    step3_android_sdk
    step4_sdk_components
    step5_create_avd
    step6_flutter
    step7_doctor

    echo ""
    log "========================================"
    log "Setup complete!"
    log "========================================"
    echo ""
    warn "IMPORTANT: Source your shell config or open a new terminal:"
    echo "    source ~/.zshrc"
    echo ""
    log "To launch the emulator:"
    echo "    emulator @pixel_api34 &"
    echo ""
    log "To verify adb sees the emulator:"
    echo "    adb devices"
    echo ""
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
