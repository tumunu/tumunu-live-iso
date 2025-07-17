# Tumunu Live ISO - Forensic Imaging Environment

## Overview

Complete forensic live environment for Tumunu digital forensics toolkit. Built on proven syslinux architecture following industry standards.

## Architecture

### Core Components
- **Syslinux Bootloader**: Reliable USB/CD boot support
- **Tumunu Core**: Main forensic imaging engine
- **Plugin System**: Modular forensic capabilities
- **Forensic Hardening**: Write-blocking and evidence protection

### Plugin Integration (8 Total)
**Proprietary Plugins (.so files):**
- `tumunu-vault-plugin`: Evidence encryption/decryption
- `tumunu-pricing-plugin`: Cost calculation and billing

**Open Source Plugins (GitHub):**
- `tumunu-ssd-forensic-plugin`: SSD-specific forensic handling
- `tumunu-testing-plugin`: Validation and integrity testing
- `tumunu-analysis-plugin`: Evidence analysis and reporting
- `tumunu-verification-plugin`: Evidence verification
- `tumunu-audit-plugin`: Audit trail and logging
- `tumunu-output-plugin`: Output formatting and reporting

## Build System

### Quick Build
```bash
make build
```

### Development Build
```bash
make dev-build
```

### USB Deployment
```bash
make usb DEVICE=/dev/sdX
```

## Project Structure

```
tumunu-live-iso/
├── build/                  # Build system and automation
│   ├── Makefile
│   ├── build-forensic.sh
│   └── validate-build.sh
├── config/                 # Live-build configuration
│   ├── bootloaders/
│   ├── package-lists/
│   ├── hooks/
│   └── includes.chroot/
├── forensic/               # Forensic integration
│   ├── tumunu-integration/
│   ├── hardening/
│   └── write-blocking/
├── plugins/                # Plugin integration
│   ├── vault/
│   ├── pricing/
│   └── ssd-forensic/
├── scripts/                # Automation scripts
├── tests/                  # Testing framework
└── docs/                   # Documentation
```

## Key Features

### Forensic Capabilities
- Write-blocking enforcement
- Chain of custody logging
- Evidence integrity verification
- Secure evidence handling
- Professional reporting

### Plugin Architecture
- Modular design
- Dynamic loading
- Secure plugin validation
- Standardized interfaces

### Build Quality
- Validated package lists
- Automated testing
- Clean build environment
- Reproducible builds

## Development

### Prerequisites
```bash
sudo apt install live-build syslinux isolinux genisoimage
```

### Testing
```bash
make test-vm      # Test in virtual machine
make test-iso     # Validate ISO structure
make test-plugins # Test plugin integration
```

## Standards Compliance

- NIST forensic guidelines
- ISO 27037 evidence handling
- Industry chain of custody
- Secure evidence processing

## Success Metrics

- ✅ Boots reliably on diverse hardware
- ✅ Write-blocking active by default
- ✅ All plugins load correctly
- ✅ Chain of custody maintained
- ✅ Evidence integrity verified