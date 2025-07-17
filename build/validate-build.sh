#!/bin/bash
# Build environment validation for Tumunu Forensic ISO
# Validates build prerequisites and environment

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

warning() {
    echo "[WARNING] $1" >&2
}

log "Validating Tumunu Forensic ISO build environment..."

# Check system requirements
log "Checking system requirements..."

# Check for required commands
REQUIRED_COMMANDS=("lb" "isohybrid" "genisoimage" "curl" "git" "cargo" "rustc")

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        log "✓ $cmd available"
    else
        warning "$cmd not available - may need to install dependencies"
    fi
done

# Check disk space
log "Checking disk space..."

WORKSPACE="/tmp/tumunu-build"
AVAILABLE_SPACE=$(df /tmp | tail -1 | awk '{print $4}')
REQUIRED_SPACE=8000000  # 8GB in KB

if [ "$AVAILABLE_SPACE" -gt "$REQUIRED_SPACE" ]; then
    log "✓ Sufficient disk space: $(($AVAILABLE_SPACE / 1024 / 1024)) GB available"
else
    error "Insufficient disk space: $(($AVAILABLE_SPACE / 1024 / 1024)) GB available, need 8GB+"
fi

# Check internet connectivity
log "Checking internet connectivity..."

if timeout 10 curl -s -o /dev/null http://deb.debian.org/debian/; then
    log "✓ Internet connectivity verified"
else
    error "Internet connectivity required for building"
fi

# Check permissions
log "Checking permissions..."

if [ "$EUID" -eq 0 ]; then
    error "Do not run as root - build script will use sudo when needed"
fi

# Check if user can use sudo
if sudo -n true 2>/dev/null; then
    log "✓ Sudo access verified"
else
    warning "Sudo access may be required for build operations"
fi

# Validate project structure
log "Validating project structure..."

REQUIRED_FILES=(
    "Makefile"
    "build/build-forensic.sh"
    "forensic/tumunu-integration/install-tumunu.sh"
    "config/hooks/normal/9000-install-tumunu.hook.chroot"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        log "✓ $file exists"
    else
        error "Required file missing: $file"
    fi
done

# Validate script syntax
log "Validating script syntax..."

SCRIPTS=(
    "build/build-forensic.sh"
    "forensic/tumunu-integration/install-tumunu.sh"
    "config/hooks/normal/9000-install-tumunu.hook.chroot"
)

for script in "${SCRIPTS[@]}"; do
    if bash -n "$PROJECT_DIR/$script"; then
        log "✓ $script syntax valid"
    else
        error "$script has syntax errors"
    fi
done

# Check Rust toolchain
log "Checking Rust toolchain..."

if command -v rustc >/dev/null 2>&1; then
    RUST_VERSION=$(rustc --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    log "Rust version: $RUST_VERSION"
    
    if [ "$(echo "$RUST_VERSION" | cut -d. -f1)" -ge 1 ] && [ "$(echo "$RUST_VERSION" | cut -d. -f2)" -ge 70 ]; then
        log "✓ Rust version sufficient for plugin compilation"
    else
        warning "Rust version may be too old - rustup will be installed during build"
    fi
else
    warning "Rust not available - rustup will be installed during build"
fi

# Check live-build version
log "Checking live-build version..."

if command -v lb >/dev/null 2>&1; then
    LB_VERSION=$(lb --version 2>/dev/null | head -1 || echo "unknown")
    log "Live-build version: $LB_VERSION"
    
    # Check if we're on a supported distribution
    if [ -f /etc/debian_version ]; then
        log "✓ Debian-based system detected"
    elif [ -f /etc/lsb-release ] && grep -q "Ubuntu" /etc/lsb-release; then
        log "✓ Ubuntu system detected"
    else
        warning "Unsupported distribution - Debian or Ubuntu recommended"
    fi
else
    warning "Live-build not available - install with: sudo apt install live-build"
fi

# Check network repositories
log "Checking network repositories..."

if timeout 10 curl -s -I http://deb.debian.org/debian/ | head -1 | grep -q "200"; then
    log "✓ Debian repository accessible"
else
    error "Debian repository not accessible"
fi

log "Build environment validation completed"
log ""
log "Summary:"
log "- Project structure: Valid"
log "- Script syntax: Valid"
log "- Build dependencies: $(command -v lb >/dev/null 2>&1 && echo "Available" || echo "Needs installation")"
log "- Disk space: $(($AVAILABLE_SPACE / 1024 / 1024)) GB available"
log "- Internet: Connected"
log "- Permissions: Ready"
log ""
log "Build environment is ready for ISO creation"