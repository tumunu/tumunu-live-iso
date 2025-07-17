#!/bin/bash
# Tumunu Forensic Live ISO Build Script
# Based on proven syslinux architecture

set -e

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="/tmp/tumunu-build"
ISO_NAME="tumunu-forensic-$(date +%Y%m%d).iso"
DEV_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dev)
            DEV_MODE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Clean and create workspace
create_workspace() {
    log "Creating clean build workspace..."
    
    sudo rm -rf "$WORKSPACE"
    mkdir -p "$WORKSPACE"
    cd "$WORKSPACE"
    
    success "Workspace created at $WORKSPACE"
}

# Configure live-build with syslinux (proven working)
configure_live_build() {
    log "Configuring live-build with syslinux..."
    
    cd "$WORKSPACE"
    
    # Configuration based on working tumunu-live-iso-v2
    lb config \
        --mode debian \
        --distribution bookworm \
        --architecture amd64 \
        --binary-images iso-hybrid \
        --bootloader syslinux \
        --debian-installer false \
        --archive-areas "main contrib non-free non-free-firmware" \
        --mirror-bootstrap http://deb.debian.org/debian/ \
        --mirror-binary http://deb.debian.org/debian/ \
        --mirror-chroot http://deb.debian.org/debian/ \
        --security false \
        --apt-recommends false \
        --apt-secure true \
        --cache-packages true \
        --debootstrap-options "--variant=minbase" \
        --bootappend-live "boot=live components quiet splash forensic"
    
    success "Live-build configured with syslinux"
}

# Create forensic package lists
create_package_lists() {
    log "Creating forensic package lists..."
    
    if [ "$DEV_MODE" = true ]; then
        # Minimal package list for development
        cat > config/package-lists/forensic-dev.list.chroot << 'EOF'
# Minimal development build
linux-image-amd64
live-boot
live-config
systemd
bash
nano
curl
wget
EOF
    else
        # Full forensic package list
        cat > config/package-lists/forensic-core.list.chroot << 'EOF'
# Core system packages
linux-image-amd64
live-boot
live-config
systemd
systemd-sysv

# Essential utilities
bash
coreutils
util-linux
procps
nano
less
tree
curl
wget
ca-certificates

# Network and hardware
network-manager
wireless-tools
firmware-linux-free
firmware-misc-nonfree
pciutils
usbutils
hdparm
smartmontools

# Forensic tools
sleuthkit
dc3dd
dcfldd
ewf-tools
afflib-tools
guymager

# Development tools for Tumunu
build-essential
cargo
rustc
git
pkg-config
libssl-dev

# Filesystem support
ntfs-3g
exfat-fuse
f2fs-tools
btrfs-progs

# Minimal desktop
xserver-xorg-core
openbox
pcmanfm
lxterminal
firefox-esr
EOF
    fi
    
    success "Package lists created"
}

# Create syslinux boot configuration
create_syslinux_config() {
    log "Creating syslinux boot configuration..."
    
    mkdir -p config/bootloaders/syslinux
    
    cat > config/bootloaders/syslinux/syslinux.cfg << 'EOF'
DEFAULT vesamenu.c32
TIMEOUT 100
MENU TITLE Tumunu Forensic Live Environment

LABEL live
    MENU LABEL ^Live System (Default)
    MENU DEFAULT
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd boot=live components quiet splash
    TEXT HELP
        Boot Tumunu forensic environment in live mode
    ENDTEXT

LABEL forensic
    MENU LABEL ^Forensic Mode (Write-Protected)
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd boot=live components quiet splash forensic
    TEXT HELP
        Boot with forensic write-blocking enabled
    ENDTEXT

LABEL safe
    MENU LABEL ^Safe Mode
    KERNEL /live/vmlinuz
    APPEND initrd=/live/initrd boot=live components single
    TEXT HELP
        Boot in safe mode for troubleshooting
    ENDTEXT

LABEL localboot
    MENU LABEL ^Local Boot
    LOCALBOOT 0
    TEXT HELP
        Exit and continue normal boot process
    ENDTEXT
EOF

    success "Syslinux boot configuration created"
}

# Copy forensic integration files
copy_forensic_files() {
    log "Copying forensic integration files..."
    
    # Create includes.chroot directory structure
    mkdir -p config/includes.chroot/opt/tumunu
    mkdir -p config/includes.chroot/etc
    
    # Create hooks directory structure  
    mkdir -p config/hooks/normal
    
    # Copy Tumunu integration script
    if [ -f "$PROJECT_DIR/forensic/tumunu-integration/install-tumunu.sh" ]; then
        cp "$PROJECT_DIR/forensic/tumunu-integration/install-tumunu.sh" config/includes.chroot/opt/tumunu/
        chmod +x config/includes.chroot/opt/tumunu/install-tumunu.sh
        log "Tumunu integration script copied to config/includes.chroot/opt/tumunu/"
        
        # Verify the copy
        if [ -f "config/includes.chroot/opt/tumunu/install-tumunu.sh" ]; then
            log "✓ Verified: Tumunu script exists in includes.chroot"
        else
            error "✗ Failed: Tumunu script missing after copy"
        fi
    else
        error "Tumunu integration script not found at: $PROJECT_DIR/forensic/tumunu-integration/install-tumunu.sh"
    fi
    
    # Copy custom hooks
    if [ -f "$PROJECT_DIR/config/hooks/normal/9000-install-tumunu.hook.chroot" ]; then
        cp "$PROJECT_DIR/config/hooks/normal/9000-install-tumunu.hook.chroot" config/hooks/normal/
        chmod +x config/hooks/normal/9000-install-tumunu.hook.chroot
        log "✓ Tumunu installation hook copied"
    else
        error "Tumunu installation hook not found"
    fi
    
    # Copy forensic hardening files
    if [ -d "$PROJECT_DIR/forensic/hardening" ]; then
        cp -r "$PROJECT_DIR/forensic/hardening"/* config/includes.chroot/etc/ 2>/dev/null || true
        log "Forensic hardening files copied"
    fi
    
    success "Forensic files copied"
}

# Build the ISO
build_iso() {
    log "Building Tumunu Forensic ISO..."
    
    cd "$WORKSPACE"
    
    # Build using live-build
    sudo lb build
    
    # Check if ISO was created
    if [ -f "live-image-amd64.hybrid.iso" ]; then
        mv "live-image-amd64.hybrid.iso" "$PROJECT_DIR/$ISO_NAME"
        success "ISO built: $PROJECT_DIR/$ISO_NAME"
    else
        error "ISO build failed - no output file"
    fi
}

# Make USB bootable
make_usb_bootable() {
    log "Making ISO USB-bootable..."
    
    cd "$PROJECT_DIR"
    
    # Make hybrid ISO
    isohybrid "$ISO_NAME"
    
    # Generate checksums
    sha256sum "$ISO_NAME" > "$ISO_NAME.sha256"
    sha512sum "$ISO_NAME" > "$ISO_NAME.sha512"
    
    success "ISO is USB-bootable"
}

# Print build summary
print_summary() {
    local iso_size=$(du -h "$PROJECT_DIR/$ISO_NAME" | cut -f1)
    local build_time=$(( $(date +%s) - $start_time ))
    local build_time_formatted=$(printf '%02d:%02d:%02d' $(($build_time/3600)) $(($build_time%3600/60)) $(($build_time%60)))
    
    echo
    echo "========================================"
    echo "TUMUNU FORENSIC ISO BUILD COMPLETE"
    echo "========================================"
    echo "ISO File: $PROJECT_DIR/$ISO_NAME"
    echo "ISO Size: $iso_size"
    echo "Build Time: $build_time_formatted"
    echo "SHA256: $(cat $PROJECT_DIR/$ISO_NAME.sha256)"
    echo "========================================"
    echo
    echo "Next steps:"
    echo "1. Test: make test-vm"
    echo "2. USB: make usb DEVICE=/dev/sdX"
    echo "3. Validate: make test"
    echo
}

# Main build process
main() {
    local start_time=$(date +%s)
    
    log "Starting Tumunu Forensic ISO build..."
    
    create_workspace
    copy_forensic_files
    configure_live_build
    create_package_lists
    create_syslinux_config
    build_iso
    make_usb_bootable
    print_summary
    
    success "Tumunu Forensic ISO build completed!"
}

# Check dependencies
check_dependencies() {
    local missing=()
    
    command -v lb >/dev/null 2>&1 || missing+=("live-build")
    command -v isohybrid >/dev/null 2>&1 || missing+=("syslinux-utils")
    command -v genisoimage >/dev/null 2>&1 || missing+=("genisoimage")
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing[*]}. Run 'make install-deps'"
    fi
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    error "Do not run as root. Script will use sudo when needed."
fi

# Run main function
check_dependencies
main "$@"