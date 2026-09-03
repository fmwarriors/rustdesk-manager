const { app, BrowserWindow, shell, dialog, screen } = require('electron');
const path = require('path');
const config = require('../server/config');

let mainWindow;
let server;
const PORT = 5050;
const DEFAULT_BOUNDS = { width: 1400, height: 900 };

function getSavedBounds() {
    const saved = config.get('window');
    if (!saved || typeof saved !== 'object') return null;

    // Discard bounds that would open the window off any connected display
    const displays = screen.getAllDisplays();
    const onScreen = displays.some(d =>
        saved.x < d.bounds.x + d.bounds.width &&
        saved.x + saved.width > d.bounds.x &&
        saved.y < d.bounds.y + d.bounds.height &&
        saved.y + saved.height > d.bounds.y
    );
    return onScreen ? saved : null;
}

function createWindow() {
    const saved = getSavedBounds();

    mainWindow = new BrowserWindow({
        width: saved?.width || DEFAULT_BOUNDS.width,
        height: saved?.height || DEFAULT_BOUNDS.height,
        x: saved?.x,
        y: saved?.y,
        minWidth: 1000,
        minHeight: 600,
        titleBarStyle: 'hiddenInset',
        trafficLightPosition: { x: 15, y: 15 },
        webPreferences: {
            nodeIntegration: false,
            contextIsolation: true,
            preload: path.join(__dirname, 'preload.js')
        },
        icon: path.join(__dirname, '../static/icon.png'),
        show: false
    });

    mainWindow.once('ready-to-show', () => {
        mainWindow.show();
    });

    mainWindow.loadURL(`http://localhost:${PORT}`);

    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        shell.openExternal(url);
        return { action: 'deny' };
    });

    let saveBoundsTimeout;
    const saveBounds = () => {
        clearTimeout(saveBoundsTimeout);
        saveBoundsTimeout = setTimeout(() => {
            if (mainWindow && !mainWindow.isDestroyed() && !mainWindow.isMaximized()) {
                config.set('window', mainWindow.getBounds());
            }
        }, 500);
    };
    mainWindow.on('resize', saveBounds);
    mainWindow.on('move', saveBounds);
    mainWindow.on('close', () => {
        if (mainWindow && !mainWindow.isMaximized()) {
            config.set('window', mainWindow.getBounds());
        }
    });

    mainWindow.on('closed', () => {
        mainWindow = null;
    });
}

function startServer() {
    try {
        server = require('../server/index');
        server.start();
        return true;
    } catch (e) {
        console.error('Error starting server:', e);
        dialog.showErrorBox('Error', `No se pudo iniciar el servidor: ${e.message}`);
        return false;
    }
}

function waitForServer(retries = 60) {
    return new Promise((resolve, reject) => {
        const http = require('http');

        const check = (attempt) => {
            const req = http.get(`http://127.0.0.1:${PORT}`, (res) => {
                resolve();
            });
            req.on('error', () => {
                if (attempt < retries) {
                    setTimeout(() => check(attempt + 1), 100);
                } else {
                    reject(new Error('Server did not start'));
                }
            });
            req.setTimeout(2000, () => {
                req.destroy();
                if (attempt < retries) {
                    setTimeout(() => check(attempt + 1), 100);
                } else {
                    reject(new Error('Server timeout'));
                }
            });
        };

        check(0);
    });
}

app.whenReady().then(async () => {
    if (!startServer()) {
        app.quit();
        return;
    }

    try {
        await waitForServer();
        createWindow();
    } catch (err) {
        dialog.showErrorBox('Error', 'No se pudo conectar con el servidor.');
        app.quit();
    }
});

app.on('window-all-closed', () => {
    if (server?.stopBackgroundTasks) {
        server.stopBackgroundTasks();
    }
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (mainWindow === null) {
        createWindow();
    }
});

app.on('before-quit', () => {
    if (server?.stopBackgroundTasks) {
        server.stopBackgroundTasks();
    }
});
