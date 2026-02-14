#!/bin/bash
set -e

# Update package lists
apt-get update

# Install Swift development tools and dependencies
echo "Installing Swift development tools..."
apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    unzip \
    libfoundation-dev \
    libuuid-dev \
    libxml2-dev \
    libcurl4-openssl-dev

# Install Swift from Swift.org
echo "Downloading and installing Swift toolchain..."
swift_version="swift-5.9.2-RELEASE"
swift_url="https://download.swift.org/swift-5.9.2-release/ubuntu2204/swift-5.9.2-RELEASE/${swift_version}-ubuntu22.04.tar.gz"
curl -L "$swift_url" -o /tmp/swift.tar.gz
tar -xzf /tmp/swift.tar.gz -C /usr/local/
ln -s /usr/local/${swift_version}-ubuntu22.04/usr/bin/swift /usr/local/bin/swift
ln -s /usr/local/${swift_version}-ubuntu22.04/usr/bin/swiftc /usr/local/bin/swiftc
ln -s /usr/local/${swift_version}-ubuntu22.04/usr/bin/swift-package /usr/local/bin/swift-package
rm /tmp/swift.tar.gz

echo "Setup complete!"
swift --version