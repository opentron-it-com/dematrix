#!/bin/bash

# Adesso Document Analyzer - Local Desktop Installer (Linux)
# This script sets up all dependencies and creates the installer

echo ""
echo "============================================"
echo "Adesso Document Analyzer - Desktop Setup"
echo "============================================"
echo ""

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js is not installed"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

echo "[1/5] Installing dependencies..."
npm install
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install dependencies"
    exit 1
fi

echo "[2/5] Checking Docker installation..."
if ! command -v docker &> /dev/null; then
    echo "WARNING: Docker is not installed"
    echo "The application requires Docker"
    echo "Please install Docker from https://docs.docker.com/engine/install/"
    exit 1
fi

echo "[3/5] Starting services..."
cd docker
docker compose up -d
cd ..
echo "Services started in background"
sleep 5

echo "[4/5] Building React application..."
npm run react-build
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build React application"
    exit 1
fi

echo "[5/5] Creating Linux installer..."
npm run build-linux
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create installer"
    exit 1
fi

echo ""
echo "============================================"
echo "Installation Complete!"
echo "============================================"
echo ""
echo "Installer created in: dist/"
echo ""
echo "System Requirements:"
echo "  - Ubuntu 18.04+ or equivalent"
echo "  - 8GB RAM (minimum)"
echo "  - 10GB free disk space"
echo "  - Docker installed and running"
echo ""
echo "To install the application:"
echo "  - AppImage: ./Adesso*.AppImage (no installation needed)"
echo "  - Debian: sudo apt install ./adesso*.deb"
echo ""
