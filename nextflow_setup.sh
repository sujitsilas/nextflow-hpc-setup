#!/usr/bin/env bash
#
# HPC & Nextflow setup script
#
# This script installs Nextflow and SquashFS, updates the bash configuration
# to load required modules and sets up environment variables for HPC usage.
#

# ------------------------------------------------------------------------------
# Configurable Variables (adjust as needed)
# ------------------------------------------------------------------------------
SQUASHFS_VERSION="4.6.1"
SQUASHFS_TARBALL="squashfs${SQUASHFS_VERSION}.tar.gz"
SQUASHFS_URL="https://sourceforge.net/projects/squashfs/files/squashfs/squashfs${SQUASHFS_VERSION}/squashfs${SQUASHFS_VERSION}.tar.gz/download"
NXF_PIPELINE="nf-core/rnaseq"

# ------------------------------------------------------------------------------
# Strict Error Handling
# ------------------------------------------------------------------------------
set -euo pipefail

# ------------------------------------------------------------------------------
# Helper Functions
# ------------------------------------------------------------------------------
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

# Safely source environment modules if available
load_modules() {
    if type module &> /dev/null; then
        # Adjust to your system's modules initialization script if needed
        if [ -f /etc/profile.d/modules.sh ]; then
            source /etc/profile.d/modules.sh
        fi
        module load python/3.9.6 || true
        module load singularity/3.8.5 || true
        module load java/jdk-17.0.12 || true
        module load java/jdk-11.0.14 || true
    else
        log "WARNING: Environment modules not found or not loaded!"
        log "Skipping module loads. Please ensure Java, Python, Singularity are available."
    fi
}

# ------------------------------------------------------------------------------
# Functions
# ------------------------------------------------------------------------------
install_nextflow() {
    log "Installing Nextflow..."

    # Make sure we have Java available (from modules or system)
    if ! command -v java &>/dev/null; then
        log "Java not found! Aborting Nextflow installation."
        exit 1
    fi

    # Create necessary directories
    mkdir -p "$HOME/.local/bin" "${SCRATCH:-/tmp}/cache"

    # Download Nextflow
    curl -fsSL https://get.nextflow.io | bash
    chmod +x nextflow
    mv nextflow "$HOME/.local/bin/"

    # Verify Nextflow installation
    if ! "$HOME/.local/bin/nextflow" -version; then
        log "Error: Nextflow installation failed"
        exit 1
    fi
}

update_environment() {
    log "Updating environment configuration..."

    # Backup existing .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.backup_$(date +'%Y%m%d_%H%M%S')"
    fi

    # Only append if not already present
    if ! grep -q "### HPC Nextflow Environment ###" "$HOME/.bashrc" 2>/dev/null; then
        cat >> "$HOME/.bashrc" <<'EOL'

### HPC Nextflow Environment ###
export PATH="$HOME/.local/bin:$PATH"
export NXF_SINGULARITY_CACHEDIR="${SCRATCH:-/tmp}/cache"

# (Optional) Additional HPC modules or paths can be placed here:
# module load python/3.9.6
# module load singularity/3.8.5
# module load java/jdk-17.0.12
# module load java/jdk-11.0.14

# Check if .local/bin is in PATH, else add it
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

EOL
        log "Appended Nextflow HPC environment config to .bashrc."
    else
        log "Nextflow HPC environment config already in .bashrc. Skipping append."
    fi

    # Source updated configuration
    # (NOTE: This will affect the current shell. If you run in a non-interactive
    #  environment, you may need to open a new shell or manually source it again.)
    source "$HOME/.bashrc"
}

install_squashfs() {
    log "Installing SquashFS version $SQUASHFS_VERSION..."

    # Create temporary download directory
    TEMP_DIR=$(mktemp -d)
    pushd "$TEMP_DIR" >/dev/null

    # Download and compile SquashFS
    wget -O "$SQUASHFS_TARBALL" "$SQUASHFS_URL"
    tar -xzf "$SQUASHFS_TARBALL"
    cd "squashfs-tools-$SQUASHFS_VERSION/squashfs-tools"

    make

    # Install binaries
    mkdir -p "$HOME/.local/bin"
    cp mksquashfs unsquashfs "$HOME/.local/bin/"

    # Verify installation
    if ! "$HOME/.local/bin/mksquashfs" -version; then
        log "Error: SquashFS installation failed"
        exit 1
    fi

    # Cleanup
    popd >/dev/null
    rm -rf "$TEMP_DIR"

    log "SquashFS installed successfully in $HOME/.local/bin."
}

pull_nextflow_pipeline() {
    local pipeline_path="$HOME/.nextflow/assets/$NXF_PIPELINE"

    log "Checking Nextflow pipeline: $NXF_PIPELINE..."
    if [ ! -d "$pipeline_path" ]; then
        log "Pipeline not found. Pulling $NXF_PIPELINE..."
        # Ensure updated environment is loaded
        source "$HOME/.bashrc"

        if ! nextflow pull "$NXF_PIPELINE"; then
            log "Error: Failed to pull pipeline $NXF_PIPELINE"
            exit 1
        fi
    else
        log "Pipeline $NXF_PIPELINE already exists at $pipeline_path."
    fi
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------
main() {
    log "Starting HPC & Nextflow environment setup..."

    # Load modules if environment modules are available
    load_modules

    install_nextflow
    update_environment
    install_squashfs
    pull_nextflow_pipeline

    log "HPC and Nextflow environment setup completed successfully!"
}

main
