#!/bin/bash
# ISO structure validation for Tumunu Forensic ISO
# Validates ISO content and structure

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

log "Validating Tumunu Forensic ISO structure..."

# Check ISO file size (should be reasonable)
ISO_SIZE=$(stat -c%s "$PROJECT_DIR/$ISO_NAME")
if [ "$ISO_SIZE" -lt 100000000 ]; then  # Less than 100MB
    error "ISO file too small: $ISO_SIZE bytes"
fi

if [ "$ISO_SIZE" -gt 10000000000 ]; then  # More than 10GB
    error "ISO file too large: $ISO_SIZE bytes"
fi

log "✓ ISO file size acceptable: $(($ISO_SIZE / 1024 / 1024)) MB"

# Check if ISO is hybrid (USB bootable)
if command -v file >/dev/null 2>&1; then
    FILE_TYPE=$(file "$PROJECT_DIR/$ISO_NAME")
    if echo "$FILE_TYPE" | grep -q "ISO 9660"; then
        log "✓ ISO format validated"
    else
        error "Invalid ISO format: $FILE_TYPE"
    fi
fi

# Check ISO contents with isoinfo if available
if command -v isoinfo >/dev/null 2>&1; then
    log "Checking ISO contents..."
    
    # Check for essential directories
    if isoinfo -l -i "$PROJECT_DIR/$ISO_NAME" | grep -q "live/"; then
        log "✓ Live system directory found"
    else
        error "Live system directory not found"
    fi
    
    # Check for kernel
    if isoinfo -l -i "$PROJECT_DIR/$ISO_NAME" | grep -q "vmlinuz"; then
        log "✓ Kernel found"
    else
        error "Kernel not found"
    fi
    
    # Check for initrd
    if isoinfo -l -i "$PROJECT_DIR/$ISO_NAME" | grep -q "initrd"; then
        log "✓ Initrd found"
    else
        error "Initrd not found"
    fi
else
    log "⚠ isoinfo not available - skipping detailed content check"
    log "Install genisoimage to run detailed ISO validation: sudo apt install genisoimage"
fi

# Verify checksums if they exist
if [ -f "$PROJECT_DIR/$ISO_NAME.sha256" ]; then
    log "Verifying SHA256 checksum..."
    cd "$PROJECT_DIR"
    if sha256sum -c "$ISO_NAME.sha256" >/dev/null 2>&1; then
        log "✓ SHA256 checksum verified"
    else
        error "SHA256 checksum verification failed"
    fi
fi

if [ -f "$PROJECT_DIR/$ISO_NAME.sha512" ]; then
    log "Verifying SHA512 checksum..."
    cd "$PROJECT_DIR"
    if sha512sum -c "$ISO_NAME.sha512" >/dev/null 2>&1; then
        log "✓ SHA512 checksum verified"
    else
        error "SHA512 checksum verification failed"
    fi
fi

log "ISO structure validation completed successfully"