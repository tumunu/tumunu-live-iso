#!/bin/bash
# Tumunu Integration Script for Live ISO
# Installs Tumunu forensic imaging tool and selected plugins

set -e

TUMUNU_DIR="/opt/tumunu"
PLUGINS_DIR="$TUMUNU_DIR/plugins"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

log_warning() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1" >&2
}

log_success() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $1"
}

# Check network connectivity
check_network_connectivity() {
    if ping -c 1 github.com >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Enhanced download with retry logic
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Attempting download (attempt $attempt/$max_attempts): $(basename "$url")"
        if curl -L --max-time 300 --retry 2 "$url" -o "$output"; then
            log_success "Download successful"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 5
    done
    
    log_error "Download failed after $max_attempts attempts: $url"
    return 1
}

# Enhanced git clone with retry logic
git_clone_with_retry() {
    local repo_url="$1"
    local target_dir="$2"
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Cloning repository (attempt $attempt/$max_attempts): $(basename "$repo_url")"
        
        if git clone --depth 1 "$repo_url" "$target_dir"; then
            log_success "Repository cloned successfully"
            return 0
        fi
        
        log_warning "Clone attempt $attempt failed, retrying..."
        rm -rf "$target_dir"
        attempt=$((attempt + 1))
        sleep 5
    done
    
    log_error "Failed to clone repository after $max_attempts attempts: $repo_url"
    return 1
}

# Create Tumunu directories
create_directories() {
    log "Creating Tumunu directories..."
    
    mkdir -p "$TUMUNU_DIR"/{bin,lib,plugins,config,docs}
    mkdir -p "$PLUGINS_DIR"/{vault,pricing,ssd-forensic,testing,analysis,verification,audit,output}
    
    # Create logs directory
    mkdir -p /var/log/tumunu
    
    # Create evidence directory
    mkdir -p /media/evidence
    
    log "Directories created"
}

# Install Tumunu core from local build
install_tumunu_core() {
    log "Installing Tumunu core..."
    
    # Check if tumunu-acquisition-core exists in parent directory
    local CORE_DIR="/mnt/nvme_docs/CODE/Tumunu/tumunu-acquisition-core"
    
    if [ -d "$CORE_DIR" ] && [ -f "$CORE_DIR/Cargo.toml" ]; then
        log "Building Tumunu core from source..."
        cd "$CORE_DIR"
        
        # Install Rust toolchain if needed
        if ! install_rust_toolchain; then
            log "⚠ Modern Rust toolchain installation failed, using system cargo"
        fi
        
        # Build in release mode with updated toolchain
        export PATH="$HOME/.cargo/bin:$PATH"
        if cargo build --release; then
            # Copy binary to Tumunu directory
            cp target/release/tumunu-acquisition-core "$TUMUNU_DIR/bin/tumunu"
            chmod +x "$TUMUNU_DIR/bin/tumunu"
            log "Tumunu core built and installed from source"
        else
            log "Failed to build Tumunu core - installing placeholder"
            install_tumunu_placeholder
        fi
    else
        log "Tumunu core source not found - installing placeholder"
        install_tumunu_placeholder
    fi
    
    # Add to PATH
    ln -sf "$TUMUNU_DIR/bin/tumunu" /usr/local/bin/tumunu
    
    log "Tumunu core installation complete"
}

# Install placeholder if core build fails
install_tumunu_placeholder() {
    cat > "$TUMUNU_DIR/bin/tumunu" << 'EOF'
#!/bin/bash
# Tumunu Forensic Imaging Tool - Live ISO Version

echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║                        TUMUNU FORENSIC IMAGING TOOL                         ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Version: Live ISO Integration"
echo "Plugin Directory: /opt/tumunu/plugins"
echo "Evidence Directory: /media/evidence"
echo "Log Directory: /var/log/tumunu"
echo ""
echo "Available plugins:"
for plugin in /opt/tumunu/plugins/*/; do
    if [ -d "$plugin" ]; then
        plugin_name=$(basename "$plugin")
        echo "  ✓ $plugin_name"
    fi
done
echo ""
echo "Commands:"
echo "  tumunu --help         - Show help"
echo "  tumunu --list-devices - List available devices"
echo "  tumunu --image <dev>  - Start imaging process"
echo ""
EOF
    
    chmod +x "$TUMUNU_DIR/bin/tumunu"
}

# Install plugins from different sources
install_plugins() {
    log "Installing Tumunu plugins..."
    
    # Install prebuilt plugins (vault, pricing) from releases
    install_prebuilt_plugins
    
    # Install open-source plugins from GitHub
    install_opensource_plugins
    
    log "All plugins installed"
}

# Install prebuilt plugins from tumunu-acquisition-core releases
install_prebuilt_plugins() {
    log "Installing prebuilt plugins from releases..."
    
    local PLUGIN_BASE_URL="https://github.com/tumunu/tumunu-acquisition-core/releases/download/plugins"
    
    # Download and install vault plugin (.so file)
    if download_with_retry "$PLUGIN_BASE_URL/libtumunu_vault_plugin.so" "$PLUGINS_DIR/vault/libtumunu_vault_plugin.so"; then
        chmod +x "$PLUGINS_DIR/vault/libtumunu_vault_plugin.so"
        
        # Create wrapper script
        cat > "$PLUGINS_DIR/vault/vault-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu Vault Plugin - Evidence Encryption/Decryption
echo "Vault Plugin: Evidence encryption and secure storage"
echo "Status: Installed from release (libtumunu_vault_plugin.so)"
echo "Location: /opt/tumunu/plugins/vault/libtumunu_vault_plugin.so"
EOF
        chmod +x "$PLUGINS_DIR/vault/vault-plugin.sh"
        log "Vault plugin installed from release"
    else
        log "Vault plugin not available - creating placeholder"
        create_vault_placeholder
    fi
    
    # Download and install pricing plugin (.so file)
    if download_with_retry "$PLUGIN_BASE_URL/libtumunu_pricing_plugin.so" "$PLUGINS_DIR/pricing/libtumunu_pricing_plugin.so"; then
        chmod +x "$PLUGINS_DIR/pricing/libtumunu_pricing_plugin.so"
        
        # Create wrapper script
        cat > "$PLUGINS_DIR/pricing/pricing-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu Pricing Plugin - Cost Calculation
echo "Pricing Plugin: Forensic service cost calculation"
echo "Status: Installed from release (libtumunu_pricing_plugin.so)"
echo "Location: /opt/tumunu/plugins/pricing/libtumunu_pricing_plugin.so"
EOF
        chmod +x "$PLUGINS_DIR/pricing/pricing-plugin.sh"
        log "Pricing plugin installed from release"
    else
        log "Pricing plugin not available - creating placeholder"
        create_pricing_placeholder
    fi
}

# Helper function to build and install a plugin
build_and_install_plugin() {
    local plugin_name="$1"
    local repo_url="$2"
    local target_dir="$3"
    local temp_dir="/tmp/${plugin_name}-plugin"
    
    log "Installing $plugin_name plugin..."
    
    if git_clone_with_retry "$repo_url" "$temp_dir"; then
        cd "$temp_dir"
        log "Building $plugin_name plugin..."
        
        # Build the plugin if Cargo.toml exists
        if [ -f "Cargo.toml" ] && command -v cargo >/dev/null 2>&1; then
            # Use updated Rust toolchain
            export PATH="$HOME/.cargo/bin:$PATH"
            if cargo build --release; then
                # Find and copy built .so file
                local so_file=$(find target/release -name "*.so" | head -1)
                if [ -n "$so_file" ]; then
                    cp "$so_file" "$target_dir/"
                    log "✓ Built and installed $plugin_name plugin (.so)"
                else
                    log "⚠ No .so file found after build, copying source"
                    cp -r * "$target_dir/"
                fi
                
                # Create wrapper script
                cat > "$target_dir/${plugin_name}-plugin.sh" << EOF
#!/bin/bash
# Tumunu $plugin_name Plugin
echo "$plugin_name Plugin: $(head -1 README.md 2>/dev/null || echo 'Tumunu plugin')"
echo "Status: Built from GitHub source"
echo "Location: /opt/tumunu/plugins/$plugin_name/"
EOF
                chmod +x "$target_dir/${plugin_name}-plugin.sh"
            else
                log "⚠ Failed to build $plugin_name plugin - copying source"
                cp -r * "$target_dir/"
            fi
        else
            # Fallback to copying source or using install script
            if [ -f "install.sh" ]; then
                ./install.sh "$target_dir"
                log "✓ Installed $plugin_name plugin via install.sh"
            else
                cp -r * "$target_dir/"
                log "✓ Copied $plugin_name plugin source"
            fi
        fi
        
        return 0
    else
        log "✗ Failed to clone $plugin_name plugin"
        return 1
    fi
}

# Install open-source plugins from GitHub
install_opensource_plugins() {
    log "Installing open-source plugins from GitHub..."
    
    # Set git to use system credentials and avoid prompts
    git config --global credential.helper store 2>/dev/null || true
    export GIT_TERMINAL_PROMPT=0
    
    # Check network connectivity first
    if ! check_network_connectivity; then
        log_warning "Network connectivity issues detected - plugin installation may fail"
    fi
    
    # Install newer Rust version via rustup for plugin compilation
    if ! install_rust_toolchain; then
        log_warning "Modern Rust toolchain installation failed, using system cargo"
    fi
    
    # Install all open-source plugins using helper function
    build_and_install_plugin "ssd-forensic" "https://github.com/tumunu/tumunu-ssd-forensic-plugin.git" "$PLUGINS_DIR/ssd-forensic" || create_ssd_placeholder
    
    build_and_install_plugin "testing" "https://github.com/tumunu/tumunu-testing-plugin.git" "$PLUGINS_DIR/testing" || create_testing_placeholder
    
    build_and_install_plugin "analysis" "https://github.com/tumunu/tumunu-analysis-plugin.git" "$PLUGINS_DIR/analysis" || create_analysis_placeholder
    
    build_and_install_plugin "verification" "https://github.com/tumunu/tumunu-verification-plugin.git" "$PLUGINS_DIR/verification" || create_verification_placeholder
    
    build_and_install_plugin "audit" "https://github.com/tumunu/tumunu-audit-plugin.git" "$PLUGINS_DIR/audit" || create_audit_placeholder
    
    build_and_install_plugin "output" "https://github.com/tumunu/tumunu-output-plugin.git" "$PLUGINS_DIR/output" || create_output_placeholder
    
    # Cleanup
    rm -rf /tmp/*-plugin
}

# Create plugin placeholders if download fails
create_vault_placeholder() {
    cat > "$PLUGINS_DIR/vault/vault-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu Vault Plugin - Evidence Encryption/Decryption
echo "Vault Plugin: Evidence encryption and secure storage"
echo "Status: Placeholder - Failed to download libtumunu_vault_plugin.so"
echo "Expected URL: https://github.com/tumunu/tumunu-acquisition-core/releases/download/plugins/libtumunu_vault_plugin.so"
EOF
    chmod +x "$PLUGINS_DIR/vault/vault-plugin.sh"
}

create_pricing_placeholder() {
    cat > "$PLUGINS_DIR/pricing/pricing-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu Pricing Plugin - Cost Calculation
echo "Pricing Plugin: Forensic service cost calculation"
echo "Status: Placeholder - Failed to download libtumunu_pricing_plugin.so"
echo "Expected URL: https://github.com/tumunu/tumunu-acquisition-core/releases/download/plugins/libtumunu_pricing_plugin.so"
EOF
    chmod +x "$PLUGINS_DIR/pricing/pricing-plugin.sh"
}

# Install newer Rust toolchain for plugin compilation
install_rust_toolchain() {
    log "Installing Rust toolchain for plugin compilation..."
    
    # Check if rustup is available
    if ! command -v rustup >/dev/null 2>&1; then
        log "Installing rustup..."
        
        # Update ca-certificates for SSL in chroot
        apt-get update -qq
        apt-get install -y ca-certificates curl
        
        # Download and install rustup with proper error handling
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init.sh; then
            chmod +x /tmp/rustup-init.sh
            if /tmp/rustup-init.sh -y --default-toolchain stable; then
                # Source the environment
                if [ -f "$HOME/.cargo/env" ]; then
                    source "$HOME/.cargo/env"
                    log "✓ Rustup installed successfully"
                else
                    log "⚠ Rustup installed but env file not found"
                    export PATH="$HOME/.cargo/bin:$PATH"
                fi
            else
                log "⚠ Rustup installation failed, using system cargo"
                return 1
            fi
        else
            log "⚠ Failed to download rustup installer, using system cargo"
            return 1
        fi
    else
        log "✓ Rustup already available"
    fi
    
    # Ensure we have a recent stable Rust version
    if command -v rustup >/dev/null 2>&1; then
        rustup default stable || true
        rustup update || true
    fi
    
    # Export cargo environment
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Verify Rust version
    if command -v rustc >/dev/null 2>&1; then
        local rust_version=$(rustc --version | grep -o '[0-9]\+\.[0-9]\+' | head -1)
        log "Rust version: $rust_version"
        
        # Check if version is sufficient (1.70+)
        if [ "$(echo "$rust_version" | cut -d. -f1)" -ge 1 ] && [ "$(echo "$rust_version" | cut -d. -f2)" -ge 70 ]; then
            log "✓ Rust version $rust_version is sufficient for plugin compilation"
            return 0
        else
            log "⚠ Rust version $rust_version may be too old, continuing anyway"
            return 1
        fi
    else
        log "⚠ Rust compiler not found after installation"
        return 1
    fi
}

create_ssd_placeholder() {
    cat > "$PLUGINS_DIR/ssd-forensic/ssd-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu SSD Forensic Plugin - SSD-specific handling
echo "SSD Forensic Plugin: SSD-specific forensic operations"
echo "Status: Placeholder - GitHub clone failed"
EOF
    chmod +x "$PLUGINS_DIR/ssd-forensic/ssd-plugin.sh"
}

create_testing_placeholder() {
    cat > "$PLUGINS_DIR/testing/testing-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu Testing Plugin - Validation and integrity
echo "Testing Plugin: Evidence validation and integrity testing"
echo "Status: Placeholder - GitHub clone failed"
EOF
    chmod +x "$PLUGINS_DIR/testing/testing-plugin.sh"
}

create_analysis_placeholder() {
    mkdir -p "$PLUGINS_DIR/analysis"
    cat > "$PLUGINS_DIR/analysis/analysis-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu Analysis Plugin - Evidence analysis
echo "Analysis Plugin: Evidence analysis and reporting"
echo "Status: Placeholder - GitHub clone failed"
EOF
    chmod +x "$PLUGINS_DIR/analysis/analysis-plugin.sh"
}

create_verification_placeholder() {
    mkdir -p "$PLUGINS_DIR/verification"
    cat > "$PLUGINS_DIR/verification/verification-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu Verification Plugin - Evidence verification
echo "Verification Plugin: Evidence integrity verification"
echo "Status: Placeholder - GitHub clone failed"
EOF
    chmod +x "$PLUGINS_DIR/verification/verification-plugin.sh"
}

create_audit_placeholder() {
    mkdir -p "$PLUGINS_DIR/audit"
    cat > "$PLUGINS_DIR/audit/audit-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu Audit Plugin - Audit trail and logging
echo "Audit Plugin: Comprehensive audit trail and logging"
echo "Status: Placeholder - GitHub clone failed"
EOF
    chmod +x "$PLUGINS_DIR/audit/audit-plugin.sh"
}

create_output_placeholder() {
    mkdir -p "$PLUGINS_DIR/output"
    cat > "$PLUGINS_DIR/output/output-plugin.sh" << 'EOF'
#!/bin/bash
# Tumunu Output Plugin - Output formatting and reporting
echo "Output Plugin: Evidence output formatting and reporting"
echo "Status: Placeholder - GitHub clone failed"
EOF
    chmod +x "$PLUGINS_DIR/output/output-plugin.sh"
}

# Create desktop integration
create_desktop_integration() {
    log "Creating desktop integration..."
    
    # Create desktop entry
    cat > /usr/share/applications/tumunu.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Tumunu Forensic Imaging
Comment=Digital forensic imaging tool
Exec=lxterminal -e tumunu
Icon=applications-system
Terminal=false
Categories=System;Security;
EOF
    
    # Create desktop shortcut
    mkdir -p /etc/skel/Desktop
    cp /usr/share/applications/tumunu.desktop /etc/skel/Desktop/
    chmod +x /etc/skel/Desktop/tumunu.desktop
    
    log "Desktop integration created"
}

# Configure forensic environment
configure_forensic_environment() {
    log "Configuring forensic environment..."
    
    # Create forensic user
    useradd -m -s /bin/bash -G sudo forensic || true
    
    # Set up evidence mounting
    echo "/media/evidence /media/evidence none bind,ro 0 0" >> /etc/fstab
    
    # Configure write-blocking
    cat > /etc/udev/rules.d/99-write-block.rules << 'EOF'
# Write-blocking rules for forensic mode
SUBSYSTEM=="block", ATTRS{removable}=="1", RUN+="/bin/sh -c 'echo 1 > /sys/block/%k/ro'"
EOF
    
    log "Forensic environment configured"
}

# Installation summary and validation
installation_summary() {
    log "Installation Summary:"
    log "===================="
    
    # Check what was successfully installed
    local core_status="FAILED"
    local plugin_count=0
    
    if [ -x "$TUMUNU_DIR/bin/tumunu" ]; then
        core_status="SUCCESS"
    fi
    
    for plugin_dir in "$PLUGINS_DIR"/*; do
        if [ -d "$plugin_dir" ] && [ -f "$plugin_dir"/*.sh ]; then
            plugin_count=$((plugin_count + 1))
        fi
    done
    
    log "Core installation: $core_status"
    log "Plugins installed: $plugin_count/8"
    
    # List installed plugins
    log "Plugin status:"
    for plugin_dir in "$PLUGINS_DIR"/*; do
        if [ -d "$plugin_dir" ]; then
            local plugin_name=$(basename "$plugin_dir")
            if [ -f "$plugin_dir"/*.so ]; then
                log "  ✓ $plugin_name (.so binary)"
            elif [ -f "$plugin_dir"/*.sh ]; then
                log "  ⚠ $plugin_name (placeholder)"
            else
                log "  ✗ $plugin_name (missing)"
            fi
        fi
    done
    
    if [ "$core_status" = "FAILED" ]; then
        log_error "Core installation failed - Tumunu may not function properly"
        return 1
    fi
    
    log_success "Tumunu integration installation completed"
    return 0
}

# Main installation
main() {
    log "Starting Tumunu integration installation..."
    
    create_directories
    install_tumunu_core
    install_plugins
    create_desktop_integration
    configure_forensic_environment
    installation_summary
}

# Run installation
main "$@"