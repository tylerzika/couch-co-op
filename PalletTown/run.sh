#!/bin/bash

# PalletTown Quick Start Script
# Run this script to immediately start playing Pallet Town in your browser

set -e

echo "🏘️  Pallet Town - Quick Start"
echo "=============================="
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is not installed"
    exit 1
fi

# Navigate to script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "✅ Python 3 found: $(python3 --version)"
echo ""

# Check if we're in the right directory
if [ ! -f "index.html" ]; then
    echo "❌ Error: index.html not found. Please run this script from the PalletTown directory"
    exit 1
fi

echo "📁 Game files found:"
echo "   ✓ index.html"
echo "   ✓ pallet-town.js"
echo "   ✓ server.py"
echo ""

echo "🚀 Starting Pallet Town Server..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python3 server.py

# The server will run until Ctrl+C is pressed
