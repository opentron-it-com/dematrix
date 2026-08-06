ADESSO DOCUMENT ANALYZER - MANUAL DOCKER IMAGE COPY

This installer does not include the large Ollama Docker image archive.
The file `ollama-ollama-latest.tar` must be copied manually after installation.

Steps:
1. Install the application using `Adesso-Document-Analyzer-Standalone-Setup.exe`.
2. Locate the separate image bundle folder containing:
   - `docker-images-archives\part3\ollama-ollama-latest.tar`
3. Copy `ollama-ollama-latest.tar` into the installed app's image folder:
   - `C:\Program Files\Adesso\DocumentAnalyzer\docker-images\`
   Or, if you chose a different install path, use `<<INSTALL_DIR>>\docker-images\`.
4. Verify the file exists at:
   - `C:\Program Files\Adesso\DocumentAnalyzer\docker-images\ollama-ollama-latest.tar`
5. Run the application using the desktop shortcut or `launch.bat`.

Why this is required:
- NSIS cannot reliably package the large Ollama image archive in this installer.
- The smaller Docker images are included in the installer.
- The launcher and `load-images.bat` script will load all `.tar` files found in `docker-images`.

If the file is missing, the first launch will fail when loading Docker images.

Support:
- If you need a different install path, copy the file into the `docker-images` folder under the chosen installation directory.
- If the installer is unable to extract other files, ensure you run it as a normal user (no admin required).
