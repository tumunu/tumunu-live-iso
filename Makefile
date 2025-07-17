# Tumunu Live ISO - Forensic Imaging Environment
# Build system based on proven syslinux architecture

.PHONY: all build clean test install-deps help dev-build usb validate

# Configuration
ISO_NAME := tumunu-forensic-$(shell date +%Y%m%d).iso
WORKSPACE := /tmp/tumunu-build
USB_DEVICE ?= /dev/sdX

# Default target
all: build

# Install build dependencies
install-deps:
	@echo "Installing build dependencies..."
	sudo apt update
	sudo apt install -y live-build syslinux isolinux genisoimage syslinux-utils

# Build forensic ISO
build: install-deps
	@echo "Building Tumunu Forensic Live ISO..."
	./build/build-forensic.sh

# Development build (minimal for testing)
dev-build: install-deps
	@echo "Building development ISO..."
	./build/build-forensic.sh --dev

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	sudo rm -rf $(WORKSPACE)
	sudo rm -rf .build/
	rm -f tumunu-forensic-*.iso*

# Test ISO in virtual machine
test-vm:
	@echo "Testing ISO in virtual machine..."
	./tests/test-vm.sh

# Test ISO structure
test-iso:
	@echo "Validating ISO structure..."
	./tests/test-iso.sh

# Test plugin integration
test-plugins:
	@echo "Testing plugin integration..."
	./tests/test-plugins.sh

# Full test suite
test: test-iso test-plugins
	@echo "All tests completed"

# Validate build environment
validate:
	@echo "Validating build environment..."
	./build/validate-build.sh

# Deploy to USB device
usb:
	@if [ "$(USB_DEVICE)" = "/dev/sdX" ]; then \
		echo "Error: Specify USB device with DEVICE=/dev/sdX"; \
		exit 1; \
	fi
	@echo "WARNING: This will overwrite $(USB_DEVICE)!"
	@echo "Press Enter to continue or Ctrl+C to cancel..."
	@read confirm
	sudo dd if=$(ISO_NAME) of=$(USB_DEVICE) bs=4M status=progress
	sudo sync
	@echo "USB deployment complete"

# Show help
help:
	@echo "Tumunu Live ISO Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build        - Build forensic ISO"
	@echo "  dev-build    - Build development ISO"
	@echo "  clean        - Clean build artifacts"
	@echo "  test         - Run test suite"
	@echo "  test-vm      - Test in virtual machine"
	@echo "  test-iso     - Validate ISO structure"
	@echo "  test-plugins - Test plugin integration"
	@echo "  validate     - Validate build environment"
	@echo "  usb          - Deploy to USB (specify DEVICE=/dev/sdX)"
	@echo "  install-deps - Install build dependencies"
	@echo "  help         - Show this help"
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make dev-build"
	@echo "  make usb DEVICE=/dev/sdb"
	@echo "  make test"

# Build info
info:
	@echo "Tumunu Forensic Live ISO Build Information"
	@echo "=========================================="
	@echo "Project: Tumunu Forensic Live Environment"
	@echo "Base: Debian 12 (Bookworm)"
	@echo "Architecture: amd64"
	@echo "Bootloader: Syslinux"
	@echo "Plugins: vault, pricing, ssd-forensic, testing"
	@echo "Build System: live-build + syslinux"
	@echo "Target: Forensic imaging workstation"
	@echo ""
	@echo "System Requirements:"
	@echo "- Root privileges (sudo)"
	@echo "- 8GB+ free disk space"
	@echo "- Internet connection"
	@echo "- live-build, syslinux, isolinux"