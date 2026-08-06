# 🚀 STANDALONE INSTALLER - BUILD & DEPLOYMENT GUIDE

## NO DOCKER DESKTOP REQUIRED

---

## 📋 WHAT THIS ACHIEVES

**Users get:**
- ✅ One EXE file (~4GB)
- ✅ Download, install, run
- ✅ No Docker Desktop needed
- ✅ No additional downloads
- ✅ Everything pre-packaged

**Installation:**
- Download + Install: 15 minutes
- First Run (with Docker init): 10-15 minutes
- Subsequent runs: 5 seconds

---

## 🛠️ BUILD PROCESS

### Phase 1: Export Docker Images (15-20 minutes)

**Prerequisites:**
- Docker Desktop running with all services healthy
- 15GB+ free disk space

**Run:**
```batch
cd C:\Users\ciorica\Documents\enterprise-doc-analyzer\installer
export-images.bat
```

**What it does:**
- Exports all 6 Docker images as TAR files
- Creates `docker-images/` directory
- Each image: 400MB - 8GB
- Total: ~11GB

**Output:**
```
docker-images/
├── enterprise-doc-analyzer-backend-latest.tar (415MB)
├── enterprise-doc-analyzer-frontend-latest.tar (625MB)
├── postgres-16-alpine.tar (420MB)
├── ghcr.io-chroma-core-chroma-latest.tar (826MB)
├── ollama-ollama-latest.tar (8.04GB)
└── nginx-alpine.tar (93.6MB)
```

**Time: 15-20 minutes**

---

### Phase 2: Compress Images (Optional - Saves bandwidth)

**If bandwidth is limited, compress:**
```batch
cd C:\Users\ciorica\Documents\enterprise-doc-analyzer\installer

REM Install 7-Zip if not already done
REM Download from: https://www.7-zip.org/

"C:\Program Files\7-Zip\7z.exe" a -t7z -m0=lzma2 -mx=9 -mfb=64 -md=32m ^
  docker-images.7z docker-images/
```

**Compression Results:**
- Before: ~11GB
- After: ~4-5GB (50-55% compression)
- Time: 10-15 minutes

**Note:** If compressing, update NSIS installer to decompress on install

---

### Phase 3: Build Installer

**Prerequisites:**
- NSIS installed: https://nsis.sourceforge.io/
- All images exported (in `docker-images/` folder)
- All scripts in place

**Build:**
```batch
cd C:\Users\ciorica\Documents\enterprise-doc-analyzer\installer

"C:\Program Files\NSIS\makensis.exe" standalone-installer.nsi
```

**Output:**
- `Adesso-Document-Analyzer-Standalone.exe` (~4-5GB)
- Located in: `installer/` directory
- Size: Depends on compression (4-11GB)

**Time: 5-10 minutes**

---

## 📊 FILES STRUCTURE

### Installer Directory After Phase 1
```
installer/
├── docker-compose.yml ✅
├── .env ✅
├── launch.bat ✅
├── stop.bat ✅
├── load-images.bat ✅
├── init-docker.bat ✅
├── standalone-launcher.bat ✅
├── README.txt ✅
├── export-images.bat ✅
├── standalone-installer.nsi ✅
│
└── docker-images/  (Created by export-images.bat)
    ├── enterprise-doc-analyzer-backend-latest.tar
    ├── enterprise-doc-analyzer-frontend-latest.tar
    ├── postgres-16-alpine.tar
    ├── ghcr.io-chroma-core-chroma-latest.tar
    ├── ollama-ollama-latest.tar
    └── nginx-alpine.tar
```

---

## 🚀 USER INSTALLATION FLOW

### Step 1: Download
- User downloads: `Adesso-Document-Analyzer-Standalone.exe` (4GB)
- Download time: 30-60 minutes (depends on internet)

### Step 2: Install
```
1. Double-click EXE
2. NSIS wizard opens
3. Choose installation directory
4. Click "Install"
5. Files extracted to: C:\Program Files\Adesso\DocumentAnalyzer
6. Shortcuts created
7. Done! (10-15 minutes)
```

### Step 3: First Launch
```
1. Click desktop shortcut "Adesso Document Analyzer"
2. System runs: standalone-launcher.bat
3. Process:
   a) Initialize Docker (1-2 minutes)
   b) Load Docker images (3-5 minutes)
   c) Create Docker network
   d) Start services (2-3 minutes)
4. Browser opens to http://localhost:3000
5. Application ready!

Total: 10-15 minutes
```

### Step 4: Daily Use
```
1. Click shortcut
2. Services start (5 seconds - already loaded)
3. Browser opens
4. Ready to work
```

---

## 🧪 TESTING ON CLEAN WINDOWS

### Test VM Setup
1. Fresh Windows 10/11 VM
2. No Docker installed
3. No Docker Desktop
4. 40GB disk space

### Test Process
1. Copy `Adesso-Document-Analyzer-Standalone.exe` to test PC
2. Run installer
3. Complete installation
4. Click shortcut
5. Verify:
   - Docker initializes
   - Images load
   - Services start
   - Browser opens to http://localhost:3000
   - Can upload documents
   - Application works

---

## 📋 DEPLOYMENT CHECKLIST

- [ ] Phase 1: Export all Docker images
  ```bash
  export-images.bat
  ```

- [ ] Verify `docker-images/` folder exists with all TAR files

- [ ] (Optional) Compress images with 7-Zip
  ```bash
  7z a -t7z -m0=lzma2 -mx=9 docker-images.7z docker-images/
  ```

- [ ] NSIS installed: `C:\Program Files\NSIS`

- [ ] Build installer
  ```bash
  standalone-installer.nsi
  ```

- [ ] Verify EXE created: `Adesso-Document-Analyzer-Standalone.exe`

- [ ] Test on clean Windows 10/11 VM

- [ ] Upload to distribution server

- [ ] Create download page

- [ ] Provide documentation to users

---

## 📚 DOCUMENTATION FOR USERS

**Include with download:**

### README.txt (in installer)
- System requirements (Windows 10/11 64-bit only)
- Installation steps (2-3 minutes)
- First launch steps (10-15 minutes)
- Subsequent launch (5 seconds)
- Features overview
- Troubleshooting

### User Guide
- How to install
- First-time setup
- Daily usage
- Accessing the application
- Stopping/restarting services
- Data backup

---

## 🆘 TROUBLESHOOTING FOR USERS

### "Windows Defender blocked installation"
- This is normal for unsigned EXEs
- Click "Run anyway"
- Consider signing EXE for production (costs ~$200/year)

### "Docker initialization failed"
- Ensure 40GB free disk space
- Check Event Viewer for errors
- Reinstall application

### "Services won't start"
- Wait 5 minutes (first time loads large images)
- Check Windows Firewall (allow Docker)
- Check available RAM (need 8GB+)

### "Can't access http://localhost:3000"
- Wait another 2-3 minutes (services take time to become healthy)
- Check: `docker compose ps` (from installation directory)
- View logs: `docker compose logs`

### "Browser doesn't open automatically"
- Manual: Open browser to http://localhost:3000
- Or double-click: `launch.bat`

---

## 💾 DISK SPACE MANAGEMENT

### Installation Requires
- Downloaded file: 4GB
- During extraction: 15GB (temporary)
- Final size: 25-30GB

### Total needed: **40GB free**

### Removing Installation
- Uninstall via Control Panel
- Application files removed
- Docker images removed
- User data preserved in: `%APPDATA%\Adesso\DocumentAnalyzer\`

---

## 🔐 SECURITY NOTES

### Standalone vs Docker Desktop
- **Standalone:** Ships with known image versions
- **Docker Desktop:** Updates may require user configuration
- **Standalone:** Easier to support and troubleshoot

### Image Verification
- Images exported from your known-good system
- Users get exactly what you tested
- No image updates from registry during installation

---

## 📦 DISTRIBUTION OPTIONS

### Option 1: Direct Download (Simplest)
- Upload `Adesso-Document-Analyzer-Standalone.exe`
- Users download directly
- Share download link

### Option 2: Split Download (Large files)
- Split EXE into parts (7-Zip can do this)
- Users download parts
- Run EXE to auto-join

### Option 3: Torrent
- Distribute large file via torrent
- Reduces server bandwidth
- Best for many users

### Option 4: USB Drive
- Copy EXE to USB drives
- Distribute physically
- No internet required

---

## ✅ FINAL CHECKLIST FOR PRODUCTION

- [ ] All 6 Docker images exported successfully
- [ ] `docker-images/` folder contains all TAR files
- [ ] All 7 script files in place
- [ ] NSIS script validated
- [ ] Installer EXE created successfully
- [ ] Size: ~4-5GB (or 11GB if uncompressed)
- [ ] Tested on clean Windows 10/11 VM
- [ ] First launch completed successfully
- [ ] All services started
- [ ] Application accessible at http://localhost:3000
- [ ] Documentation complete
- [ ] Ready for production distribution

---

## 🎉 YOU'RE DONE!

**Adesso Document Analyzer - Truly Standalone Installer**

✅ No Docker Desktop required
✅ One-click installation
✅ Professional user experience
✅ Enterprise-grade packaging

**Users can:**
1. Download one file
2. Install with one click
3. Launch with one click
4. Use immediately

**Ready to distribute!** 🚀
