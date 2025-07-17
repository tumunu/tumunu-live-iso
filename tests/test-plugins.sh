#!/bin/bash
# Plugin integration testing for Tumunu Forensic ISO
# Tests plugin installation and integration

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Test plugin installation script
log "Testing plugin installation script..."

INSTALL_SCRIPT="$PROJECT_DIR/forensic/tumunu-integration/install-tumunu.sh"
if [ ! -f "$INSTALL_SCRIPT" ]; then
    error "Plugin installation script not found: $INSTALL_SCRIPT"
fi

# Check script syntax
if bash -n "$INSTALL_SCRIPT"; then
    log "✓ Plugin installation script syntax valid"
else
    error "Plugin installation script has syntax errors"
fi

# Check for required functions
REQUIRED_FUNCTIONS=("create_directories" "install_tumunu_core" "install_plugins" "install_prebuilt_plugins" "install_opensource_plugins")

for func in "${REQUIRED_FUNCTIONS[@]}"; do
    if grep -q "^$func()" "$INSTALL_SCRIPT"; then
        log "✓ Function $func found"
    else
        error "Required function $func not found"
    fi
done

# Test plugin directory structure
log "Testing plugin directory structure..."

PLUGIN_DIRS=("vault" "pricing" "ssd-forensic" "testing" "analysis" "verification" "audit" "output")

for plugin in "${PLUGIN_DIRS[@]}"; do
    if [ -d "$PROJECT_DIR/plugins/$plugin" ]; then
        log "✓ Plugin directory $plugin exists"
    else
        log "⚠ Plugin directory $plugin missing - will be created during build"
    fi
done

# Test plugin URLs and GitHub connectivity
log "Testing plugin repository connectivity..."

GITHUB_REPOS=(
    "https://github.com/tumunu/tumunu-ssd-forensic-plugin.git"
    "https://github.com/tumunu/tumunu-testing-plugin.git"
    "https://github.com/tumunu/tumunu-analysis-plugin.git"
    "https://github.com/tumunu/tumunu-verification-plugin.git"
    "https://github.com/tumunu/tumunu-audit-plugin.git"
    "https://github.com/tumunu/tumunu-output-plugin.git"
)

for repo in "${GITHUB_REPOS[@]}"; do
    if timeout 10 git ls-remote "$repo" >/dev/null 2>&1; then
        log "✓ Repository accessible: $repo"
    else
        log "⚠ Repository not accessible: $repo"
    fi
done

# Test proprietary plugin URLs
log "Testing proprietary plugin download URLs..."

PROPRIETARY_URLS=(
    "https://github.com/tumunu/tumunu-acquisition-core/releases/download/plugins/libtumunu_vault_plugin.so"
    "https://github.com/tumunu/tumunu-acquisition-core/releases/download/plugins/libtumunu_pricing_plugin.so"
)

for url in "${PROPRIETARY_URLS[@]}"; do
    if timeout 10 curl -s -I "$url" | head -1 | grep -q "200\|302"; then
        log "✓ Proprietary plugin accessible: $url"
    else
        log "⚠ Proprietary plugin not accessible: $url"
    fi
done

# Test Rust toolchain requirements
log "Testing Rust toolchain requirements..."

if command -v rustc >/dev/null 2>&1; then
    RUST_VERSION=$(rustc --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
    log "System Rust version: $RUST_VERSION"
    
    # Check if version is sufficient (1.70+)
    if [ "$(echo "$RUST_VERSION" | cut -d. -f1)" -ge 1 ] && [ "$(echo "$RUST_VERSION" | cut -d. -f2)" -ge 70 ]; then
        log "✓ System Rust version sufficient for plugin compilation"
    else
        log "⚠ System Rust version may be too old - rustup installation required"
    fi
else
    log "⚠ Rust not available on system - rustup installation will be attempted"
fi

log "Plugin integration testing completed"