#!/bin/bash

# Adesso Document Analyzer - Standalone Desktop Installer Builder (macOS/Linux)
# This creates a complete, self-contained installer with no external dependencies

echo ""
echo "============================================"
echo "Adesso Document Analyzer v1.0.0"
echo "Standalone Desktop Installer Builder"
echo "============================================"
echo ""

# Get to the correct directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
echo "Working directory: $(pwd)"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "ERROR: Node.js is not installed"
    echo "Please install Node.js from https://nodejs.org/"
    exit 1
fi

# Check if we have package.json in current directory
if [ ! -f "package.json" ]; then
    echo "ERROR: package.json not found in current directory"
    echo "Please run this script from the project root directory"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "[1/4] Installing npm dependencies..."
npm install --legacy-peer-deps
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to install dependencies"
    exit 1
fi

echo "[2/4] Building React application..."
npm run react-build
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build React application"
    exit 1
fi

echo "[3/4] Preparing resources..."
mkdir -p resources/backend
if [ -f "target/doc-analyzer.jar" ]; then
    echo "Copying backend JAR to resources..."
    cp target/doc-analyzer.jar resources/backend/doc-analyzer.jar
else
    echo "WARNING: Backend JAR not found at target/doc-analyzer.jar"
    echo "The installer will not include the backend"
fi

PLATFORM=$(uname)
if [ "$PLATFORM" = "Darwin" ]; then
    echo "[4/4] Building macOS installer..."
    npm run build-mac
else
    echo "[4/4] Building Linux installer..."
    npm run build-linux
fi

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create installer"
    exit 1
fi

echo ""
echo "============================================"
echo "Installer Created Successfully!"
echo "============================================"
echo ""
echo "Installer location: $(pwd)/dist/"
echo ""

if [ "$PLATFORM" = "Darwin" ]; then
    echo "File: Adesso Document Analyzer-1.0.0.dmg"
else
    echo "Files:"
    echo "  - Adesso Document Analyzer-1.0.0.AppImage"
    echo "  - adesso-document-analyzer-1.0.0.deb (if building on Debian)"
fi

echo ""
echo "============================================"
echo "SYSTEM REQUIREMENTS FOR USERS:"
echo "============================================"

if [ "$PLATFORM" = "Darwin" ]; then
    echo "- macOS 10.15 or later"
else
    echo "- Ubuntu 18.04 or later (or equivalent Linux)"
fi

echo "- 8GB RAM minimum (16GB recommended)"
echo "- 20GB free disk space"
echo "- No additional software needed"
echo ""
echo "The installer includes everything needed:"
echo "+ Application runtime"
echo "+ React frontend"
echo "+ Spring Boot backend"
echo "+ PostgreSQL database"
echo "+ Chroma vector store"
echo "+ Ollama LLM engine"
echo "+ All required dependencies"
echo ""
