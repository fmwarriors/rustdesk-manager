const express = require('express');
const path = require('path');
const fs = require('fs');
const nunjucks = require('nunjucks');
const db = require('./database');
const config = require('./config');
const api = require('./api');
const { getTranslations, supportedLanguages } = require('./i18n');

const app = express();
const PORT = 5050;

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
let apiToken = null;
let apiTokenExpires = 0;

// Get API token
async function getApiToken() {
    if (apiToken && Date.now() < apiTokenExpires) {
        return apiToken;
    }

    const server = config.get('server');
    if (!server?.password) return null;

    try {
        const resp = await api.post(`${server.api_url}/api/login`, {
            username: server.username,
            password: server.password
        });
        if (resp.access_token) {
            apiToken = resp.access_token;
            apiTokenExpires = Date.now() + 1800000; // 30 min
            return apiToken;
        }
    } catch (e) {
        console.error('Error getting API token:', e.message);
    }
    return null;
}

// Fetch peers from server
async function fetchPeersFromServer() {
    const token = await getApiToken();
    if (!token) return [];

    const server = config.get('server');
    try {
        const resp = await api.get(
            `${server.api_url}/api/admin/peer/list?page=1&page_size=1000`,
            { 'Api-Token': token }
        );
        return resp?.data?.list || [];
    } catch (e) {
        console.error('Error fetching peers:', e.message);
    }
    return [];
}

// Fetch peers status
async function fetchPeersStatus() {
    const peers = await fetchPeersFromServer();
    const now = Date.now() / 1000;
    const result = {};
    for (const peer of peers) {
        const lastOnline = peer.last_online_time || 0;
        result[peer.id] = (now - lastOnline < 60) ? 'online' : 'offline';
    }
    return result;
}

// Sync with server
async function syncWithServer() {
    const peers = await fetchPeersFromServer();
    if (!peers.length) return [];

    const localIds = db.getAllRustdeskIds();
    const newDevices = [];

    for (const peer of peers) {
        const peerId = peer.id;
        if (peerId && !localIds.has(peerId)) {
            const hostname = peer.hostname || '';
            const osInfo = peer.os || '';
            const name = hostname || `Equipo ${peerId}`;

            const deviceId = db.createDeviceFromServer(peerId, name, hostname, osInfo);
            newDevices.push({
                id: deviceId,
                rustdesk_id: peerId,
                name,
                hostname,
                os: osInfo
            });
            console.log(`[SYNC] Nuevo equipo importado: ${name} (${peerId})`);
        }
    }
    return newDevices;
}

// Update all device status
async function updateAllDeviceStatus() {
    const peersStatus = await fetchPeersStatus();
    const devices = db.getAllDevices();

    for (const device of devices) {
        deviceStatusCache[device.rustdesk_id] = peersStatus[device.rustdesk_id] || 'unknown';
    }
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

app.get('/api/status', (req, res) => {
    res.json(deviceStatusCache);
});

app.post('/api/status/:rustdeskId', (req, res) => {
    const { rustdeskId } = req.params;
    const { status } = req.body;
    deviceStatusCache[rustdeskId] = status || 'unknown';
    res.json({ success: true });
});

app.post('/api/sync', async (req, res) => {
    const newDevices = await syncWithServer();
    await updateAllDeviceStatus();
    res.json({ success: true, new_devices: newDevices, new_count: newDevices.length });
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
    deviceStatusCache[device.rustdesk_id] = 'connecting';

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
    apiToken = null;
    apiTokenExpires = 0;
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
let statusInterval, syncInterval;

function startBackgroundTasks() {
    const statusSeconds = config.get('status.interval_seconds') || 30;
    const syncSeconds = config.get('sync.interval_seconds') || 60;

    statusInterval = setInterval(async () => {
        if (config.isConfigured()) {
            await updateAllDeviceStatus();
        }
    }, statusSeconds * 1000);

    syncInterval = setInterval(async () => {
        if (config.isConfigured() && config.get('sync.auto_sync')) {
            const newDevices = await syncWithServer();
            if (newDevices.length) {
                console.log(`[SYNC] ${newDevices.length} nuevos equipos importados`);
            }
        }
    }, syncSeconds * 1000);
}

function stopBackgroundTasks() {
    if (statusInterval) clearInterval(statusInterval);
    if (syncInterval) clearInterval(syncInterval);
}

// Start server
async function start() {
    await db.init();

    const server = config.get('server');
    if (config.isConfigured()) {
        console.log(`📡 Servidor API configurado: ${server?.api_url}`);
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
