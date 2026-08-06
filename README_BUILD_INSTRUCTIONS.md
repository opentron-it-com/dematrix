# Build Instructions - Adesso Document Analyzer Desktop

## Quick Start

### Windows
```batch
cd /d C:\path\to\project
build-standalone-installer.bat
```

### macOS/Linux
```bash
cd /path/to/project
bash build-standalone-installer.sh
```

---

## What Happens During Build

1. **Dependencies** - npm install (30 sec - 2 min)
2. **Build Frontend** - React compile (1-3 min)
3. **Copy Backend** - JAR to resources (10 sec)
4. **Package App** - electron-builder (5-10 min)
5. **Create Installer** - Platform-specific (2-5 min)

**Total Time: 10-20 minutes**

---

## Output Files

After build completes, find installers in `dist/` folder:

- **Windows**: `Adesso Document Analyzer Setup 1.0.0.exe`
- **macOS**: `Adesso Document Analyzer-1.0.0.dmg`
- **Linux**: `Adesso Document Analyzer-1.0.0.AppImage`

Each file is 500MB - 2GB (complete standalone application)

---

## Prerequisites (For Developer Building)

- Node.js 14 or later
- npm (included with Node.js)
- Project source code
- Backend JAR pre-built at `target/doc-analyzer.jar`

---

## Testing the Installer

1. Download the `.exe`/`.dmg`/`.AppImage` from `dist/`
2. Transfer to test machine (or VM)
3. Run installer
4. Follow installation wizard
5. Launch application from shortcut
6. Verify all features work

---

## System Requirements for End Users

Users will need:
- Windows 10/11 64-bit (or macOS 10.15+ or Ubuntu 18.04+)
- 8GB RAM minimum
- 20GB free disk space
- Nothing else - everything else is bundled

---

## Documentation for Users

When distributing the installer, also provide:

1. `USER_INSTALLATION_GUIDE.md` - Step-by-step instructions
2. `STANDALONE_INSTALLER_GUIDE.md` - Technical overview
3. `FINAL_VERIFICATION_CHECKLIST.md` - What's included

---

## Troubleshooting the Build Process

### Issue: "npm not found" or "Node.js not installed"
**Solution:** Install Node.js from https://nodejs.org/

### Issue: "package.json not found"
**Solution:** Ensure you're running the script from the project root directory

### Issue: "Backend JAR not found"
**Solution:** Build backend first with Maven: `mvn clean package`
JAR should be at: `target/doc-analyzer.jar`

### Issue: Build fails with errors
**Solution:**
1. Delete `node_modules` folder
2. Delete `.next` folder (if exists)
3. Run `npm cache clean --force`
4. Try the build again

### Issue: Build is very slow
**Solution:**
- First build is slowest (downloads dependencies)
- Ensure at least 2GB free disk space
- Close other applications
- Check internet connection

---

## Distribution Steps

1. Run build script: `build-standalone-installer.bat` (or .sh)
2. Find installer in `dist/` folder
3. Upload to your distribution server/website
4. Share download link with users
5. Users download and install on their PC
6. Done - no Docker needed, no setup, just works

---

## First Run Experience for Users

When users launch the app for the first time:

1. Desktop shortcut is clicked
2. Application window opens (5-10 seconds)
3. Services initialize automatically
4. Models download (if needed - only first time)
5. Dashboard displays
6. Ready to use

Subsequent launches: 5-10 seconds, everything already running

---

## Build Errors Reference

| Error | Cause | Solution |
|-------|-------|----------|
| "node_modules not found" | Missing dependencies | Run `npm install` |
| "Cannot find module" | Corrupted node_modules | Delete and reinstall |
| "React compilation error" | Syntax error in source | Check frontend source files |
| "Electron-builder not found" | Missing dev dependency | Run `npm install --save-dev electron-builder` |
| "JAR not found" | Backend not built | Build with `mvn clean package` |

---

**Status: READY TO BUILD** ✅

