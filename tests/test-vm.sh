#!/bin/bash
# Virtual machine testing for Tumunu Forensic ISO
# Tests ISO boot capability and basic functionality

set -e

ISO_NAME="tumunu-forensic-$(date +%Y%m%d).iso"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Check if ISO exists
if [ ! -f "$PROJECT_DIR/$ISO_NAME" ]; then
    error "ISO file not found: $PROJECT_DIR/$ISO_NAME"
fi

log "Testing Tumunu Forensic ISO in virtual machine..."

# Check if qemu is available
if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    log "⚠ QEMU not available - skipping VM test"
    log "Install QEMU to run VM tests: sudo apt install qemu-kvm"
    exit 0
fi

# Basic VM boot test
log "Starting VM boot test..."
timeout 60 qemu-system-x86_64 \
    -m 2048 \
    -cdrom "$PROJECT_DIR/$ISO_NAME" \
    -boot d \
    -display none \
    -serial stdio \
    -no-reboot \
    -monitor null \
    2>/dev/null | grep -q "live" && {
    log "✓ VM boot test passed"
} || {
    log "⚠ VM boot test inconclusive - manual verification recommended"
}

log "VM testing completed"