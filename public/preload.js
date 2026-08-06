const { contextBridge, ipcMain } = require('electron');

contextBridge.exposeInMainWorld('electron', {
  appVersion: async () => await ipcRenderer.invoke('get-app-version'),
  platform: async () => await ipcRenderer.invoke('get-platform'),
  appPath: async () => await ipcRenderer.invoke('get-app-path')
});
