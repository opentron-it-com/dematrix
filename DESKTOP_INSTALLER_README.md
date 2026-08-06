# Adesso Document Analyzer - Desktop Application Installer Guide

## Overview
This is a standalone desktop application that runs locally with all dependencies bundled. No cloud connectivity required.

## System Requirements

### Windows
- Windows 10/11 64-bit
- 8GB RAM minimum (16GB recommended)
- 10GB free disk space
- Docker Desktop installed

### macOS
- macOS 10.15 or later
- 8GB RAM minimum (16GB recommended)
- 10GB free disk space
- Docker Desktop installed

### Linux
- Ubuntu 18.04+ or equivalent
- 8GB RAM minimum (16GB recommended)
- 10GB free disk space
- Docker installed

## Installation Instructions

### Windows
1. Run `build-installer-windows.bat`
2. Wait for build to complete (5-10 minutes)
3. Go to `dist/` folder
4. Run `Adesso Document Analyzer Setup 1.0.0.exe`
5. Follow the installation wizard
6. Launch from Start Menu or Desktop shortcut

### macOS
1. Run `bash build-installer-macos.sh`
2. Wait for build to complete (5-10 minutes)
3. Go to `dist/` folder
4. Open `Adesso Document Analyzer-1.0.0.dmg`
5. Drag to Applications folder
6. Launch from Applications

### Linux
1. Run `bash build-installer-linux.sh`
2. Wait for build to complete (5-10 minutes)
3. Go to `dist/` folder
   - **AppImage**: Run `./Adesso\ Document\ Analyzer-1.0.0.AppImage` (no installation needed)
   - **Debian**: Run `sudo apt install ./adesso-document-analyzer-1.0.0.deb`

## What Gets Installed

- **Frontend**: React single-page application
- **Backend**: Spring Boot Java service (runs locally)
- **Services**: Docker containers for:
  - PostgreSQL 16 (database)
  - Chroma (vector store)
  - Ollama (LLM engine with Qwen2.5:0.5B)

All services are containerized and managed automatically by the application.

## First Run

1. Launch the application
2. Wait 10-15 seconds for services to start
3. Application window opens automatically
4. All data stored locally in Docker volumes

## Data Storage

All data is stored locally in Docker volumes:
- Documents in PostgreSQL
- Embeddings in Chroma
- Models in Ollama

**Data is NOT sent to any cloud service.**

## Uninstallation

### Windows
- Control Panel → Programs → Adesso Document Analyzer → Uninstall
- Or use `Add/Remove Programs`

### macOS
- Drag Adesso Document Analyzer from Applications to Trash
- Empty Trash

### Linux
- **AppImage**: Delete the .AppImage file
- **Debian**: `sudo apt remove adesso-document-analyzer`

## Troubleshooting

### "Docker not found" error
- Install Docker Desktop from https://www.docker.com/products/docker-desktop
- Ensure Docker is running before launching the application

### Application won't start
1. Check Docker is running: `docker ps`
2. Check logs in application console (View → Toggle Dev Tools)
3. Ensure ports 3000, 8080, 5432, 6333, 11434 are not in use

### Performance issues
- Close other applications
- Increase Docker resource allocation (Docker Desktop → Settings → Resources)
- Allocate at least 4 CPU cores and 8GB memory to Docker

## Support

For issues or questions, contact Adesso support.

## Version
v1.0.0 - Local Desktop Edition
