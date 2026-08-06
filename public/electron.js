const { app, BrowserWindow, Menu, ipcMain, dialog } = require('electron');
const path = require('path');
const isDev = require('electron-is-dev');
const { spawn, exec } = require('child_process');
const fs = require('fs');
const os = require('os');

let mainWindow;
let backendProcess;

const APP_DATA = path.join(os.homedir(), '.adesso-analyzer');
const SERVICES_DIR = path.join(APP_DATA, 'services');
const DATA_DIR = path.join(APP_DATA, 'data');
const LOGS_DIR = path.join(APP_DATA, 'logs');

// Ensure app data directories exist
[APP_DATA, SERVICES_DIR, DATA_DIR, LOGS_DIR].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1600,
    height: 1000,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    icon: path.join(__dirname, 'assets', 'icon.png')
  });

  const startUrl = isDev
    ? 'http://localhost:3000'
    : `file://${path.join(__dirname, 'app.html')}`;

  mainWindow.loadURL(startUrl);

  if (isDev) {
    mainWindow.webContents.openDevTools();
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

function getEmbeddedJarPath() {
  // In production, JAR is bundled in asar archive
  const paths = [
    path.join(__dirname, '../resources/backend/doc-analyzer.jar'),
    path.join(__dirname, '../../resources/backend/doc-analyzer.jar'),
    path.join(process.resourcesPath, 'backend/doc-analyzer.jar'),
    path.join(app.getAppPath(), 'resources/backend/doc-analyzer.jar')
  ];

  for (const p of paths) {
    if (fs.existsSync(p)) {
      return p;
    }
  }

  return null;
}

function startBackend() {
  return new Promise((resolve) => {
    const jarPath = getEmbeddedJarPath();

    if (!jarPath) {
      console.error('Backend JAR not found in any expected location');
      resolve(false);
      return;
    }

    console.log('Starting backend from:', jarPath);

    const javaArgs = [
      '-Xmx2g',
      `-Dspring.datasource.url=jdbc:postgresql://localhost:5432/docdb`,
      `-Dspring.datasource.username=docuser`,
      `-Dspring.datasource.password=docpass123`,
      `-Dapp.chroma.url=http://localhost:8000`,
      `-Dapp.ollama.url=http://localhost:11434`,
      '-jar',
      jarPath
    ];

    backendProcess = spawn('java', javaArgs, {
      stdio: ['ignore', 'pipe', 'pipe'],
      detached: false
    });

    let startupTimeout = false;

    backendProcess.stdout.on('data', (data) => {
      const message = data.toString();
      console.log(`[Backend] ${message}`);
      if (message.includes('Started') || message.includes('Application ready')) {
        if (!startupTimeout) {
          startupTimeout = true;
          resolve(true);
        }
      }
    });

    backendProcess.stderr.on('data', (data) => {
      console.error(`[Backend Error] ${data}`);
    });

    backendProcess.on('close', (code) => {
      console.log(`Backend process exited with code ${code}`);
    });

    // Timeout after 30 seconds
    setTimeout(() => {
      if (!startupTimeout) {
        startupTimeout = true;
        resolve(true);
      }
    }, 30000);
  });
}

function initializeServices() {
  return new Promise((resolve) => {
    console.log('Initializing embedded services...');
    
    // Create necessary directories
    const pgDataDir = path.join(DATA_DIR, 'postgres');
    const chromaDataDir = path.join(DATA_DIR, 'chroma');
    const ollamaDataDir = path.join(DATA_DIR, 'ollama');

    [pgDataDir, chromaDataDir, ollamaDataDir].forEach(dir => {
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
    });

    resolve(true);
  });
}

async function checkJavaInstallation() {
  return new Promise((resolve) => {
    exec('java -version', (error, stdout, stderr) => {
      resolve(!error);
    });
  });
}

async function initializeApp() {
  try {
    console.log('Initializing application...');

    // Check Java installation
    const javaInstalled = await checkJavaInstallation();
    if (!javaInstalled) {
      dialog.showErrorBox(
        'Java Not Found',
        'Java Runtime is required but not found.\n\n' +
        'This should have been installed with the application.\n\n' +
        'Please reinstall the application or contact support.'
      );
      app.quit();
      return;
    }

    console.log('Java found');

    // Initialize service directories
    await initializeServices();

    console.log('Starting backend service...');
    const backendOk = await startBackend();

    if (!backendOk) {
      console.error('Backend start may have failed, continuing anyway...');
    }

    console.log('Creating application window...');
    createWindow();
  } catch (error) {
    console.error('Initialization error:', error);
    dialog.showErrorBox('Startup Error', error.message);
    app.quit();
  }
}

app.on('ready', () => {
  initializeApp();
});

app.on('window-all-closed', () => {
  stopAllServices();
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (mainWindow === null) {
    createWindow();
  }
});

function stopAllServices() {
  console.log('Stopping all services...');

  // Kill backend
  if (backendProcess) {
    try {
      if (process.platform === 'win32') {
        spawn('taskkill', ['/pid', backendProcess.pid, '/f']);
      } else {
        process.kill(-backendProcess.pid);
      }
    } catch (error) {
      console.error('Error killing backend:', error);
    }
  }
}

// IPC handlers
ipcMain.handle('get-app-version', () => {
  return app.getVersion();
});

ipcMain.handle('get-app-path', () => {
  return APP_DATA;
});

ipcMain.handle('get-platform', () => {
  return process.platform;
});

// Menu
const menu = Menu.buildFromTemplate([
  {
    label: 'File',
    submenu: [
      {
        label: 'Exit',
        accelerator: 'CmdOrCtrl+Q',
        click: () => {
          app.quit();
        }
      }
    ]
  },
  {
    label: 'Edit',
    submenu: [
      { role: 'undo' },
      { role: 'redo' },
      { type: 'separator' },
      { role: 'cut' },
      { role: 'copy' },
      { role: 'paste' }
    ]
  },
  {
    label: 'View',
    submenu: [
      { role: 'reload' },
      { role: 'forceReload' },
      ...(isDev ? [{ role: 'toggleDevTools' }] : [])
    ]
  },
  {
    label: 'Help',
    submenu: [
      {
        label: 'About',
        click: () => {
          if (mainWindow) {
            dialog.showMessageBox(mainWindow, {
              type: 'info',
              title: 'About Adesso Document Analyzer',
              message: 'Adesso Document Analyzer v1.0.0',
              detail: 'Enterprise Document Analysis Platform\n\nAll services run locally and independently.\nNo external connections required.'
            });
          }
        }
      }
    ]
  }
]);

Menu.setApplicationMenu(menu);

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});
