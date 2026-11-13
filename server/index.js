const express = require('express');
const path = require('path');
const fs = require('fs');
const nunjucks = require('nunjucks');
const db = require('./database');
const config = require('./config');
const { queryPresence } = require('./presence');
const { getTranslations, supportedLanguages } = require('./i18n');

const app = express();
const PORT = parseInt(process.env.RDM_PORT, 10) || 5050; // RDM_PORT solo para pruebas

// Middleware
app.use(express.json());
app.use('/static', express.static(path.join(__dirname, '..', 'static')));

// Template engine
nunjucks.configure(path.join(__dirname, '..', 'templates'), {
    autoescape: true,
    express: app
});

// Device status cache
let deviceStatusCache = {};
// Host del servidor de IDs (hbbs). Si no se indica, se deduce de la URL del servidor API.
function getIdServerHost() {
    const server = config.get('server') || {};
    if (server.id_server && server.id_server.trim()) {
        return server.id_server.trim().replace(/^[a-z]+:\/\//i, '').replace(/[:/].*$/, '');
    }
    try {
        return server.api_url ? new URL(server.api_url).hostname : '';
    } catch (e) {
        return '';
    }
}

// Actualiza el estado online/offline de todos los equipos de la agenda
let statusRefreshing = null;
async function updateAllDeviceStatus() {
    if (statusRefreshing) return statusRefreshing;
    statusRefreshing = (async () => {
        const host = getIdServerHost();
        if (!host) return;
        const devices = db.getAllDevices();
        try {
            const presence = await queryPresence(host, devices.map((d) => d.rustdesk_id));
            const next = {};
            for (const device of devices) {
                next[device.rustdesk_id] = presence[device.rustdesk_id] || 'unknown';
            }
            deviceStatusCache = next;
        } catch (e) {
            // Sin respuesta del servidor: no se sabe nada, no se afirma ni online ni offline
            console.error('Error consultando presencia:', e.message);
            deviceStatusCache = {};
        }
    })().finally(() => { statusRefreshing = null; });
    return statusRefreshing;
}

// Routes
app.get('/', (req, res) => {
    const categories = db.getAllCategories();
    const groups = db.getAllGroups();
    const devices = db.getAllDevices();
    const server = config.get('server') || {};
    const lang = config.get('language') || 'es';
    const t = getTranslations(lang);
    res.render('index.html', {
        categories,
        groups,
        devices,
        rustdesk_server: server.api_url || '',
        lang,
        t,
        supportedLanguages
    });
});

app.get('/api/status', async (req, res) => {
    if (statusRefreshing) await statusRefreshing;
    res.json(deviceStatusCache);
});

app.get('/api/sync/pending', (req, res) => {
    const unassigned = db.getUnassignedDevicesCount();
    res.json({ new_devices: [], unassigned_count: unassigned });
});

app.get('/api/devices', (req, res) => {
    const { search, group_id } = req.query;
    let devices;
    if (search) {
        devices = db.searchDevices(search);
    } else if (group_id) {
        devices = db.getDevicesByGroup(group_id === 'null' ? null : parseInt(group_id));
    } else {
        devices = db.getAllDevices();
    }
    res.json(devices);
});

app.post('/api/devices', (req, res) => {
    const { rustdesk_id, name, password, description, group_id, color, os_type } = req.body;
    const lang = config.get('language') || 'es';
    const t = getTranslations(lang);
    const existing = db.getDeviceByRustdeskId(rustdesk_id);
    if (existing) {
        if (existing.group_id === null) {
            return res.status(400).json({ error: t.device_exists_unassigned });
        }
        return res.status(400).json({ error: 'Ya existe un equipo con este ID de RustDesk' });
    }
    const id = db.createDevice(rustdesk_id, name, password, description, group_id, color, os_type);
    updateAllDeviceStatus();
    res.json({ id, success: true });
});

app.put('/api/devices/:id', (req, res) => {
    const deviceId = parseInt(req.params.id);
    const { rustdesk_id, name, password, description, group_id, color, os_type } = req.body;
    const existing = db.getDeviceByRustdeskId(rustdesk_id, deviceId);
    if (existing) {
        return res.status(400).json({ error: 'Ya existe un equipo con este ID de RustDesk' });
    }
    db.updateDevice(deviceId, rustdesk_id, name, password, description, group_id, color, os_type);
    updateAllDeviceStatus();
    res.json({ success: true });
});

app.delete('/api/devices/:id', (req, res) => {
    db.deleteDevice(parseInt(req.params.id));
    res.json({ success: true });
});

app.post('/api/devices/:id/connect', (req, res) => {
    const device = db.getDevice(parseInt(req.params.id));
    if (!device) return res.status(404).json({ error: 'Device not found' });

    db.updateLastConnected(device.id);

    const rustdeskConfig = config.get('rustdesk') || {};
    const platform = process.platform;
    let rustdeskBin;

    if (platform === 'darwin') {
        rustdeskBin = rustdeskConfig.path_mac || '/Applications/RustDesk.app/Contents/MacOS/RustDesk';
    } else if (platform === 'win32') {
        rustdeskBin = rustdeskConfig.path_windows || 'C:\\Program Files\\RustDesk\\rustdesk.exe';
    } else {
        rustdeskBin = rustdeskConfig.path_linux || 'rustdesk';
    }

    const { spawn } = require('child_process');
    const args = ['--connect', device.rustdesk_id];
    if (device.password) args.push('--password', device.password);

    try {
        spawn(rustdeskBin, args, { detached: true, stdio: 'ignore' }).unref();
        res.json({ success: true, message: `Connecting to ${device.rustdesk_id}` });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

app.post('/api/devices/:id/transfer', (req, res) => {
    const device = db.getDevice(parseInt(req.params.id));
    if (!device) return res.status(404).json({ error: 'Device not found' });

    db.updateLastConnected(device.id);

    const rustdeskConfig = config.get('rustdesk') || {};
    const platform = process.platform;
    let rustdeskBin;

    if (platform === 'darwin') {
        rustdeskBin = rustdeskConfig.path_mac || '/Applications/RustDesk.app/Contents/MacOS/RustDesk';
    } else if (platform === 'win32') {
        rustdeskBin = rustdeskConfig.path_windows || 'C:\\Program Files\\RustDesk\\rustdesk.exe';
    } else {
        rustdeskBin = rustdeskConfig.path_linux || 'rustdesk';
    }

    const { spawn } = require('child_process');
    const args = ['--file-transfer', device.rustdesk_id];
    if (device.password) args.push('--password', device.password);

    try {
        spawn(rustdeskBin, args, { detached: true, stdio: 'ignore' }).unref();
        res.json({ success: true, message: `Opening file transfer to ${device.rustdesk_id}` });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// Categories
app.get('/api/categories', (req, res) => {
    res.json(db.getAllCategories());
});

app.post('/api/categories', (req, res) => {
    const { name, color } = req.body;
    const id = db.createCategory(name, color);
    res.json({ id, success: true });
});

app.put('/api/categories/:id', (req, res) => {
    const { name, color } = req.body;
    db.updateCategory(parseInt(req.params.id), name, color);
    res.json({ success: true });
});

app.delete('/api/categories/:id', (req, res) => {
    db.deleteCategory(parseInt(req.params.id));
    res.json({ success: true });
});

app.post('/api/categories/:id/toggle', (req, res) => {
    db.toggleCategoryCollapsed(parseInt(req.params.id));
    res.json({ success: true });
});

// Groups
app.get('/api/groups', (req, res) => {
    res.json(db.getAllGroups());
});

app.post('/api/groups', (req, res) => {
    const { name, parent_id, color, category_id } = req.body;
    const id = db.createGroup(name, parent_id, color, category_id);
    res.json({ id, success: true });
});

app.put('/api/groups/:id', (req, res) => {
    const { name, parent_id, color, category_id } = req.body;
    db.updateGroup(parseInt(req.params.id), name, parent_id, color, category_id);
    res.json({ success: true });
});

app.delete('/api/groups/:id', (req, res) => {
    db.deleteGroup(parseInt(req.params.id));
    res.json({ success: true });
});

// Status refresh
app.post('/api/status/refresh', async (req, res) => {
    await updateAllDeviceStatus();
    res.json(deviceStatusCache);
});

// Config
app.get('/api/config', (req, res) => {
    const cfg = config.load();
    if (cfg.server?.password) {
        cfg.server.password = '***';
    }
    res.json(cfg);
});

app.post('/api/config', (req, res) => {
    const data = req.body;
    const current = config.load();

    for (const [section, values] of Object.entries(data)) {
        if (typeof values === 'object' && values !== null) {
            if (!current[section]) current[section] = {};
            for (const [key, value] of Object.entries(values)) {
                if (key === 'password' && value === '***') continue;
                current[section][key] = value;
            }
        } else {
            // Handle non-object values like 'language'
            current[section] = values;
        }
    }

    config.save(current);
    updateAllDeviceStatus();
    res.json({ success: true });
});

app.post('/api/config/test', async (req, res) => {
    const { api_url, username, password } = req.body;
    const result = await config.testConnection(api_url, username, password);
    res.json(result);
});

app.get('/api/config/status', (req, res) => {
    res.json({
        configured: config.isConfigured(),
        first_run: config.get('first_run')
    });
});

// Import/Export
app.get('/api/export', async (req, res) => {
    try {
        const dbData = db.exportAll();
        const configData = config.load();

        const exportData = {
            version: 1,
            exported_at: new Date().toISOString(),
            config: configData,
            database: dbData
        };

        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Content-Disposition', `attachment; filename=rustdesk-manager-backup-${new Date().toISOString().slice(0,10)}.json`);
        res.json(exportData);
    } catch (e) {
        console.error('Export error:', e);
        res.status(500).json({ error: e.message });
    }
});

// Archivo .rdconfig para el instalador de RustDesk (macOS): servidor, key y contraseña
app.post('/api/installer-config', (req, res) => {
    const clean = (v) => String(v || '').replace(/[\r\n]+/g, ' ').trim();
    const name = clean(req.body?.name);
    let server = clean(req.body?.server).replace(/^[A-Za-z]+:\/\//, '').split(/[/:]/)[0];
    const key = clean(req.body?.key);
    const password = clean(req.body?.password);

    if (!name) return res.status(400).json({ error: 'name' });
    if (!/^[A-Za-z0-9.-]+$/.test(server)) return res.status(400).json({ error: 'server' });
    if (!/^[A-Za-z0-9+/=_-]+$/.test(key)) return res.status(400).json({ error: 'key' });
    if (!password) return res.status(400).json({ error: 'password' });

    const text = `# Configuración de RustDesk — ${name}\n` +
        `# Haz doble clic en este archivo (o déjalo en el Escritorio) y abre «Instalar RustDesk».\n` +
        `# Contiene la contraseña de acceso: envíalo solo a su destinatario.\n\n` +
        `NOMBRE=${name}\nSERVIDOR=${server}\nKEY=${key}\nCONTRASENA=${password}\n`;
    res.setHeader('Content-Type', 'text/plain; charset=utf-8');
    res.json({ filename: `${name.replace(/[\/:]/g, '-')}.rdconfig`, content: text });
});

app.post('/api/import', express.json({ limit: '50mb' }), async (req, res) => {
    try {
        const { config: importConfig, database: importDb } = req.body;

        if (importConfig) {
            config.save(importConfig);
        }

        if (importDb) {
            db.importAll(importDb);
        }

        res.json({ success: true });
    } catch (e) {
        console.error('Import error:', e);
        res.status(500).json({ error: e.message });
    }
});

// Language
app.get('/api/i18n', (req, res) => {
    const lang = config.get('language') || 'es';
    res.json({
        lang,
        translations: getTranslations(lang),
        supportedLanguages
    });
});

// Background tasks
let statusInterval;

function startBackgroundTasks() {
    const statusSeconds = config.get('status.interval_seconds') || 15;

    updateAllDeviceStatus();
    statusInterval = setInterval(updateAllDeviceStatus, statusSeconds * 1000);
}

function stopBackgroundTasks() {
    if (statusInterval) clearInterval(statusInterval);
}

// Start server
async function start() {
    await db.init();

    const server = config.get('server');
    if (getIdServerHost()) {
        console.log(`📡 Servidor de IDs para estado online: ${getIdServerHost()}`);
    } else {
        console.log('⚠️  Servidor no configurado - accede a Ajustes para configurar');
    }

    const unassigned = db.getUnassignedDevicesCount();
    if (unassigned > 0) {
        console.log(`⚠️  ${unassigned} equipos sin clasificar`);
    }

    startBackgroundTasks();

    app.listen(PORT, '127.0.0.1', () => {
        console.log(`🖥️  RustDesk Manager iniciado en http://localhost:${PORT}`);
    });
}

module.exports = { start, stopBackgroundTasks };

// Run directly
if (require.main === module) {
    start();
}
