# User Installation Guide - Adesso Document Analyzer

## Download & Install

### Windows

#### Step 1: Download
- Download `Adesso Document Analyzer Setup 1.0.0.exe` from your email or link provided
- File size: 500MB - 2GB
- Estimated download time: 5-30 minutes depending on your internet

#### Step 2: Install
1. Double-click `Adesso Document Analyzer Setup 1.0.0.exe`
2. Click "Install"
3. Choose installation location (default is recommended):
   - `C:\Program Files\Adesso\DocumentAnalyzer`
4. Wait for installation to complete (2-5 minutes)
5. Click "Finish"

#### Step 3: Launch
- Click the shortcut on your Desktop OR
- Search for "Adesso Document Analyzer" in Start Menu
- First launch: 10-30 seconds (services starting)
- Subsequent launches: 5-10 seconds

---

### macOS

#### Step 1: Download
- Download `Adesso Document Analyzer-1.0.0.dmg` from your email or link provided
- File size: 500MB - 2GB
- Estimated download time: 5-30 minutes depending on your internet

#### Step 2: Install
1. Open the `.dmg` file (double-click or drag from Downloads)
2. Drag "Adesso Document Analyzer" to the "Applications" folder
3. Wait for copy to complete (1-2 minutes)
4. Close the DMG window

#### Step 3: Launch
- Open "Applications" folder
- Find "Adesso Document Analyzer"
- Double-click to launch
- First launch: 10-30 seconds (services starting)
- Subsequent launches: 5-10 seconds

**Note:** If you get a security warning:
1. Open System Preferences → Security & Privacy
2. Click "Open Anyway"
3. Enter your password if prompted

---

### Linux

#### Step 1: Download
- Download `Adesso Document Analyzer-1.0.0.AppImage` OR `adesso-document-analyzer-1.0.0.deb`
- File size: 500MB - 2GB
- Estimated download time: 5-30 minutes depending on your internet

#### Step 2a: Using AppImage (No Installation Needed)
1. Open the downloaded file location
2. Right-click `Adesso Document Analyzer-1.0.0.AppImage`
3. Properties → Permissions → Check "Execute"
4. Double-click to launch
5. First launch: 10-30 seconds (services starting)

#### Step 2b: Using Debian Package
1. Open terminal in download folder
2. Run: `sudo apt install ./adesso-document-analyzer-1.0.0.deb`
3. Enter your password when prompted
4. Installation completes automatically
5. Search for "Adesso Document Analyzer" in Applications menu

#### Step 3: Launch
- From AppImage: Double-click the file
- From Debian: Search in Applications menu or run: `adesso-document-analyzer`

---

## First Run - What to Expect

### Startup Process (Normal - Don't Close)
1. Application window opens
2. Services starting in background...
   - PostgreSQL database initializing
   - Chroma vector store starting
   - Ollama LLM engine launching
3. Models downloading (if first time - 5-10 minutes, only happens once)
4. Application dashboard loads

**Total first-run time: 10-30 seconds** (or 5-10 minutes if models need to download)

### After First Run
- Subsequent launches take 5-10 seconds
- All data cached locally
- No re-downloading needed

---

## System Requirements Verification

Before you install, please verify:

### Windows
```
✓ Windows 10 or later?     Yes / No
✓ 64-bit system?           Yes / No
✓ 8GB RAM?                 Yes / No
✓ 20GB free disk space?    Yes / No
✓ Administrator access?    Yes / No (needed for installation)
```

### macOS
```
✓ macOS 10.15 or later?    Yes / No
✓ 8GB RAM?                 Yes / No
✓ 20GB free disk space?    Yes / No
```

### Linux
```
✓ Ubuntu 18.04 or later?   Yes / No
✓ 64-bit system?           Yes / No
✓ 8GB RAM?                 Yes / No
✓ 20GB free disk space?    Yes / No
```

---

## Troubleshooting

### Application Won't Start
1. Restart your computer
2. Restart the application
3. Check disk space (need 20GB free)
4. Check RAM (need 8GB)

### Application Crashes on Startup
- First run takes longer (models downloading)
- If crash persists, try:
  1. Wait 15-30 seconds longer on first launch
  2. Restart the application
  3. Check system resources

### "Out of Memory" Error
- Your computer may need more RAM
- Close other applications
- Increase virtual memory/page file:
  - Windows: Control Panel → System → Advanced System Settings → Performance Settings → Advanced → Virtual Memory
  - macOS: This should not happen with 8GB+ RAM
  - Linux: Increase swap space

### Very Slow Performance
- Close unnecessary applications
- Ensure 20GB+ free disk space
- Move large files if disk near full
- Restart computer

### Can't Find the Application After Install
- Windows: Search for "Adesso" in Start Menu
- macOS: Open Applications folder, look for "Adesso Document Analyzer"
- Linux: Search for "Adesso" in application launcher

---

## Uninstalling

### Windows
1. Open Start Menu
2. Search for "Uninstall"
3. Click "Uninstall a program"
4. Find "Adesso Document Analyzer"
5. Click "Uninstall"
6. Confirm removal
7. Done

Or:
1. Go to `C:\Program Files\Adesso\DocumentAnalyzer`
2. Double-click `uninstall.exe`
3. Confirm removal

### macOS
1. Open Applications folder
2. Find "Adesso Document Analyzer"
3. Drag to Trash
4. Empty Trash
5. Done

### Linux (AppImage)
- Simply delete the `.AppImage` file
- No installation registry to clean up

### Linux (Debian)
```bash
sudo apt remove adesso-document-analyzer
```

---

## Data Storage

All your data is stored locally on your computer:

- **Windows**: `C:\Users\[YourUsername]\.adesso-analyzer\`
- **macOS**: `/Users/[YourUsername]/.adesso-analyzer/`
- **Linux**: `/home/[username]/.adesso-analyzer/`

### What's Stored?
- Your uploaded documents (NOT sent to cloud)
- Database (PostgreSQL)
- Vector embeddings (Chroma)
- LLM models (Ollama)
- Application logs

**Privacy:** All data remains on your computer. No cloud sync. No telemetry.

---

## Support

If you need help:
1. Check this guide
2. Contact Adesso support with:
   - Your operating system and version
   - Available RAM
   - Free disk space
   - Error messages (if any)
   - Screenshot of the issue

---

## Version Information

**Application Version:** 1.0.0
**Release Date:** 2024
**Platform:** Windows 10+, macOS 10.15+, Linux Ubuntu 18.04+

**Happy analyzing!** 🎯
