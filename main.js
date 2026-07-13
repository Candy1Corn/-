const { app, BrowserWindow, ipcMain, screen } = require('electron');
const path = require('path');

const SPRITE_SIZE = 32;
const SCALE = 4;           // 32 * 4 = 128px display size — crisp on HiDPI
const WIN_SIZE = SPRITE_SIZE * SCALE;

let win;

function createWindow() {
  const { width, height } = screen.getPrimaryDisplay().workAreaSize;

  win = new BrowserWindow({
    width: WIN_SIZE + 160,   // extra width for speech bubble overflow
    height: WIN_SIZE + 48,   // extra height for bubble above
    x: width - WIN_SIZE - 120,
    y: height - WIN_SIZE - 60,
    transparent: true,
    frame: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    resizable: false,
    hasShadow: false,
    focusable: false,        // won't steal focus from your work
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js'),
    },
  });

  win.loadFile('index.html');

  // Start with mouse pass-through; renderer toggles this on hover
  win.setIgnoreMouseEvents(true, { forward: true });

  ipcMain.on('mouse-ignore', (_, v) => {
    win.setIgnoreMouseEvents(v, { forward: true });
  });

  ipcMain.on('move-by', (_, dx, dy) => {
    const [x, y] = win.getPosition();
    const { width: sw, height: sh } = screen.getPrimaryDisplay().workAreaSize;
    const nx = Math.max(0, Math.min(sw - WIN_SIZE, x + dx));
    const ny = Math.max(0, Math.min(sh - WIN_SIZE, y + dy));
    win.setPosition(Math.round(nx), Math.round(ny));
  });

  ipcMain.on('move-to', (_, x, y) => {
    const { width: sw, height: sh } = screen.getPrimaryDisplay().workAreaSize;
    const nx = Math.max(0, Math.min(sw - WIN_SIZE, x));
    const ny = Math.max(0, Math.min(sh - WIN_SIZE - 10, y));
    win.setPosition(Math.round(nx), Math.round(ny));
  });

  ipcMain.handle('get-state', () => {
    const [x, y] = win.getPosition();
    const { width: sw, height: sh } = screen.getPrimaryDisplay().workAreaSize;
    return { x, y, sw, sh, winSize: WIN_SIZE };
  });
}

app.whenReady().then(createWindow);
app.on('window-all-closed', () => app.quit());
