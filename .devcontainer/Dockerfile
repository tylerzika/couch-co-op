FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Arguments
ARG SWIFT_VERSION=5.9.2
ARG INSTALL_SWIFT=true

# Install C/C++ build essentials, CMake, and development tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    gdb \
    cmake \
    ninja-build \
    pkg-config \
    libssl-dev \
    libz-dev \
    curl \
    wget \
    git \
    vim \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Install Swift if requested
RUN if [ "$INSTALL_SWIFT" = "true" ]; then \
    apt-get update && apt-get install -y \
    swift \
    sourcekit-lsp \
    && rm -rf /var/lib/apt/lists/*; \
    fi

# Verify installations
RUN swift --version && \
    gcc --version && \
    cmake --version && \
    sourcekit-lsp --version || echo "sourcekit-lsp not available"

# Create a working directory
WORKDIR /workspace

# Ensure Swift package manager cache is initialized
RUN swift --version && \
    swift build --version

ENTRYPOINT ["/bin/bash"]
