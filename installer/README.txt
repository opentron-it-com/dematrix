ADESSO DOCUMENT ANALYZER - STANDALONE INSTALLER
v1.0.0

========================================
SYSTEM REQUIREMENTS
========================================

REQUIRED:
- Windows 10/11 64-bit
- 8GB RAM minimum (16GB recommended)
- 30GB free disk space
- Internet connection for first-time SharePoint downloads

========================================
INSTALLATION
========================================

1. Download and run: Adesso-Document-Analyzer-Setup-1.0.0.exe
2. Follow the installation wizard
3. Install location is automatically set to your user profile
   (no administrator rights required)
4. Installer will extract the bundled Docker engine and launcher files
5. Installation complete!

========================================
FIRST RUN
========================================

1. Double-click desktop shortcut: "Adesso Document Analyzer"
   OR search for it in Start Menu
   
2. First launch will:
   - Start the bundled Docker engine from your AppData install
   - Download any missing large payloads from SharePoint
   - Load required Docker images into the local engine
   - Launch services (PostgreSQL, Chroma, Ollama, Backend, Frontend)
   - Open browser to http://localhost:3000
   
3. Wait 5-15 minutes for downloads and initialization on first run

========================================
ACCESSING THE APPLICATION
========================================

Frontend UI:      http://localhost:3000
Backend API:      http://localhost:8080/api
Vector Database:  http://localhost:8002
LLM Engine:       http://localhost:11434

========================================
DATA STORAGE
========================================

All application data is stored locally in:
- Windows: %LOCALAPPDATA%\Adesso\DocumentAnalyzer

Data includes:
- Documents you upload
- PostgreSQL database
- Vector embeddings (Chroma)
- Ollama models

NO data is sent to cloud. 100% local storage.

========================================
STOPPING THE APPLICATION
========================================

Option 1: Run stop.bat from installation directory
Option 2: Close the application window (services continue running)

Data is preserved. Run launch.bat to restart.

========================================
UNINSTALLING
========================================

1. Open Control Panel > Programs and Features
2. Find "Adesso Document Analyzer"
3. Click Uninstall
4. Follow the uninstall wizard

To preserve data, backup %LOCALAPPDATA%\Adesso\DocumentAnalyzer before uninstalling.

========================================
TROUBLESHOOTING
========================================

ERROR: Docker engine cannot start
- Verify your user has rights to run applications from AppData
- If needed, restart Windows and try again

ERROR: Required payloads are missing
- Ensure SharePoint access is available for payload download
- Check the log file in the installation folder

ERROR: Services won't start
- Check: docker compose logs
- Ensure sufficient disk space
- Try: restart the launcher

ERROR: Can't access http://localhost:3000
- Wait 60 seconds for services to become healthy
- Check the launcher output and logs

========================================
FEATURES
========================================

✓ Enterprise document analysis
✓ Vector-based semantic search
✓ CV to requirement matching
✓ Multi-document chat
✓ AI-powered insights
✓ 100% local - no cloud dependency
✓ No external API calls
✓ Fully containerized
✓ One-click installation

========================================
SUPPORT
========================================

For issues or questions, contact:
support@adesso.com

Visit documentation:
https://docs.adesso.com

========================================
VERSION INFORMATION
========================================

Version: 1.0.0
Release Date: August 2024
Platform: Windows 10/11 64-bit
Architecture: Docker Compose

Components:
- Frontend: React 18
- Backend: Spring Boot
- Database: PostgreSQL 16
- Vector Store: Chroma
- LLM: Ollama
- Reverse Proxy: Nginx

========================================
