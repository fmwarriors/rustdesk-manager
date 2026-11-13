const fs = require('fs');
const path = require('path');
const axios = require('axios');

let configPath;

function getConfigPath() {
    if (configPath) return configPath;

    try {
        const { app } = require('electron');
        if (app) {
            configPath = path.join(app.getPath('userData'), 'config.json');
            return configPath;
        }
    } catch (e) {}

    configPath = path.join(__dirname, '..', 'config.json');
    return configPath;
}

const DEFAULT_CONFIG = {
    server: {
        api_url: '',
        username: '',
        password: '',
        rustdesk_key: '',
        id_server: ''
    },
    language: 'es',
    status: {
        interval_seconds: 15,
        online_threshold_seconds: 60
    },
    rustdesk: {
        path_mac: '/Applications/RustDesk.app/Contents/MacOS/RustDesk',
        path_windows: 'C:\\Program Files\\RustDesk\\rustdesk.exe',
        path_linux: 'rustdesk',
        default_password: ''
    },
    ui: {
        theme: 'light',
        view_mode: 'grid',
        show_offline: true
    },
    first_run: true
};

function load() {
    const configFile = getConfigPath();
    if (!fs.existsSync(configFile)) {
        save(DEFAULT_CONFIG);
        return { ...DEFAULT_CONFIG };
    }

    try {
        const data = JSON.parse(fs.readFileSync(configFile, 'utf-8'));
        return deepMerge({ ...DEFAULT_CONFIG }, data);
    } catch (e) {
        console.error('Error loading config:', e);
        return { ...DEFAULT_CONFIG };
    }
}

function save(config) {
    try {
        fs.writeFileSync(getConfigPath(), JSON.stringify(config, null, 2), 'utf-8');
        return true;
    } catch (e) {
        console.error('Error saving config:', e);
        return false;
    }
}

function get(key) {
    const config = load();
    if (!key) return config;

    const keys = key.split('.');
    let value = config;
    for (const k of keys) {
        if (value && typeof value === 'object' && k in value) {
            value = value[k];
        } else {
            return null;
        }
    }
    return value;
}

function set(key, value) {
    const config = load();
    const keys = key.split('.');
    let target = config;

    for (let i = 0; i < keys.length - 1; i++) {
        if (!(keys[i] in target)) {
            target[keys[i]] = {};
        }
        target = target[keys[i]];
    }

    target[keys[keys.length - 1]] = value;
    return save(config);
}

function deepMerge(base, override) {
    const result = { ...base };
    for (const [key, value] of Object.entries(override)) {
        if (key in result && typeof result[key] === 'object' && typeof value === 'object' && !Array.isArray(value)) {
            result[key] = deepMerge(result[key], value);
        } else {
            result[key] = value;
        }
    }
    return result;
}

async function testConnection(apiUrl, username, password) {
    // Si se indica usar la guardada
    if (password === '__USE_STORED__') {
        const config = load();
        password = config.server?.password || '';
    }

    if (!password) {
        return { success: false, message: 'Contraseña no configurada' };
    }

    try {
        const resp = await axios.post(`${apiUrl}/api/login`, {
            username,
            password
        }, { timeout: 10000 });

        if (resp.status === 200 && resp.data?.access_token) {
            return { success: true, message: 'Conexión exitosa' };
        }
        return { success: false, message: 'Credenciales inválidas' };
    } catch (e) {
        if (e.code === 'ECONNREFUSED' || e.code === 'ENOTFOUND') {
            return { success: false, message: 'No se puede conectar al servidor' };
        }
        if (e.code === 'ETIMEDOUT' || e.code === 'TIMEOUT') {
            return { success: false, message: 'Tiempo de espera agotado' };
        }
        return { success: false, message: e.message };
    }
}

function isConfigured() {
    const config = load();
    return Boolean(config.server?.password);
}

function markFirstRunComplete() {
    set('first_run', false);
}

module.exports = {
    load,
    save,
    get,
    set,
    testConnection,
    isConfigured,
    markFirstRunComplete,
    DEFAULT_CONFIG
};
