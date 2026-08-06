# Adesso Document Analyzer - Standalone Installer Guide

## 📦 What You Have

A complete standalone installer package for Adesso Document Analyzer with:
- ✅ Docker Compose configuration
- ✅ NSIS installer script
- ✅ Installation & launch scripts
- ✅ User documentation

## 🚀 How to Build the Installer

### Prerequisites
1. **NSIS Installer** - Download from https://nsis.sourceforge.io/
   - Install to default location: `C:\Program Files\NSIS`
   
2. **Docker Desktop** - Already installed on your system

### Build Steps

**Option 1: Automated Build**
```batch
cd C:\Users\ciorica\Documents\enterprise-doc-analyzer\installer
build-installer.bat
```

**Option 2: Manual Build with NSIS**
```batch
cd C:\Users\ciorica\Documents\enterprise-doc-analyzer\installer
"C:\Program Files\NSIS\makensis.exe" installer.nsi
```

### Output
- File: `Adesso-Document-Analyzer-Setup-1.0.0.exe`
- Location: `installer/` folder
- Size: ~100MB (compressed, grows to ~15GB when extracting with data)

## 📋 Installer Contents

```
installer/
├── docker-compose.yml          (Docker service definitions)
├── .env                        (Environment configuration)
├── launch.bat                  (Start services script)
├── stop.bat                    (Stop services script)
├── README.txt                  (User documentation)
├── installer.nsi               (NSIS script)
├── build-installer.bat         (Build script)
└── install.bat                 (Legacy installer)
```

## 🎯 What the Installer Does

### Installation Phase
1. ✅ Checks Windows version (10/11 64-bit)
2. ✅ Verifies Docker Desktop is installed
3. ✅ Creates installation directory: `C:\Program Files\Adesso\DocumentAnalyzer`
4. ✅ Creates data directory: `%APPDATA%\Adesso\DocumentAnalyzer`
5. ✅ Copies Docker Compose files
6. ✅ Creates desktop & Start Menu shortcuts
7. ✅ Registers in Windows Control Panel

### First Run
1. ✅ Checks Docker daemon
2. ✅ Starts all services (docker compose up -d)
3. ✅ Waits for services to be healthy
4. ✅ Opens browser to http://localhost:3000

### User Data
- Stored in: `%APPDATA%\Adesso\DocumentAnalyzer\`
- All data remains after uninstall if not explicitly removed

## 📊 System Requirements for Users

**Minimum:**
- Windows 10 or later (64-bit)
- Docker Desktop installed
- 8GB RAM
- 30GB free disk space
- Internet connection (first-run setup)

**Recommended:**
- Windows 11 64-bit
- Docker Desktop with 16GB allocated
- 16GB RAM
- 50GB SSD space
- Fast internet for model downloads

## 🔧 Installation Distribution

### Step 1: Build the Installer
```batch
cd installer/
build-installer.bat
```
Creates: `Adesso-Document-Analyzer-Setup-1.0.0.exe`

### Step 2: Test the Installer
1. Copy `Adesso-Document-Analyzer-Setup-1.0.0.exe` to a test location
2. Run it
3. Test installation and first launch

### Step 3: Distribute
- Upload to your download server
- Share via email
- Distribute on USB
- Upload to GitHub releases

### Step 4: User Installation
Users simply:
1. Download: `Adesso-Document-Analyzer-Setup-1.0.0.exe`
2. Double-click to run
3. Follow wizard
4. Click desktop shortcut to launch

## 🎨 Customization

### Change Company Name
Edit `installer.nsi`:
```
Name "Your Company - Document Analyzer"
OutFile "Your-Company-Setup-1.0.0.exe"
```

### Change Installation Path
Edit `installer.nsi`:
```
InstallDir "$PROGRAMFILES64\YourCompany\App"
```

### Add Custom Logo/Icon
Place in `installer/` directory and add to `.nsi`:
```
!define MUI_ICON "your-icon.ico"
```

### Change Application URL
Edit `launch.bat`:
```
start http://your-domain.com:3000
```

## 🧹 Cleanup & Maintenance

### Remove Old Installations
```batch
# Manual uninstall
1. Control Panel > Programs > Uninstall
2. Find "Adesso Document Analyzer"
3. Click Uninstall

# OR delete manually
rmdir /s "%ProgramFiles%\Adesso\DocumentAnalyzer"
```

### Preserve User Data
Before uninstalling:
```batch
# Backup user data
xcopy "%APPDATA%\Adesso\DocumentAnalyzer" "D:\Backup\" /E /I
```

### Clean Docker Images (Optional)
```batch
docker system prune -a --volumes
```

## 📦 Release Checklist

- [ ] NSIS installed on build machine
- [ ] Docker Compose files up to date
- [ ] .env configured correctly
- [ ] build-installer.bat tested
- [ ] Installer EXE created successfully
- [ ] Test installation on clean Windows 10/11 VM
- [ ] Verify all services start correctly
- [ ] Test http://localhost:3000 access
- [ ] Test uninstall process
- [ ] Update version number if needed
- [ ] Sign installer (optional, requires certificate)
- [ ] Upload to server
- [ ] Update download links
- [ ] Create release notes

## 🔐 Security Notes

### Installer Security
- Run installer as Administrator (Windows handles this)
- Verify NSIS download from official source
- Sign installer with code certificate (optional)

### Application Security
- All data stored locally
- No telemetry sent
- No cloud connectivity required
- Docker containers isolated
- PostgreSQL password in `.env` (change for production)

## 🆘 Troubleshooting

### "Docker not installed" error
- Install Docker Desktop from https://www.docker.com/products/docker-desktop
- Ensure Docker is in system PATH
- Restart installer

### "NSIS not found" error
- Install NSIS from https://nsis.sourceforge.io/
- Default path: `C:\Program Files\NSIS`
- Try build script again

### Installer won't start
- Run as Administrator
- Disable antivirus temporarily
- Try again

### Services won't start after install
- Check Docker Desktop is running
- Verify port 3000, 8080 are not in use
- Check available disk space (need 30GB+)
- Review README.txt for detailed help

## 📞 Support

For issues building or distributing the installer:
- Check README.txt in installer directory
- Review launcher scripts (launch.bat, stop.bat)
- Verify Docker Compose configuration
- Check documentation

---

## 🎉 You're Done!

Your standalone installer is ready for distribution. Users can now:
1. Download one file
2. Install with one click
3. Launch with one click
4. Access full application at http://localhost:3000

**No Docker knowledge required. No configuration needed. True plug-and-play!**
