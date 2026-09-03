const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

let db;
let dbPath;

function getDbPath() {
    if (dbPath) return dbPath;

    try {
        const { app } = require('electron');
        if (app && app.isPackaged) {
            dbPath = path.join(app.getPath('userData'), 'rustdesk_manager.db');
            return dbPath;
        }
    } catch (e) {}

    dbPath = path.join(__dirname, '..', 'rustdesk_manager.db');
    return dbPath;
}

function saveDb() {
    if (db) {
        const data = db.export();
        const buffer = Buffer.from(data);
        fs.writeFileSync(getDbPath(), buffer);
    }
}

async function init() {
    const SQL = await initSqlJs();
    const dbFile = getDbPath();

    if (fs.existsSync(dbFile)) {
        const buffer = fs.readFileSync(dbFile);
        db = new SQL.Database(buffer);
    } else {
        db = new SQL.Database();
    }

    db.run(`
        CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            color TEXT DEFAULT '#6366f1',
            collapsed INTEGER DEFAULT 0,
            sort_order INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            parent_id INTEGER,
            category_id INTEGER,
            color TEXT DEFAULT '#6366f1',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (parent_id) REFERENCES groups(id) ON DELETE SET NULL,
            FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
        );

        CREATE TABLE IF NOT EXISTS devices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            rustdesk_id TEXT NOT NULL,
            password TEXT,
            name TEXT NOT NULL,
            description TEXT,
            group_id INTEGER,
            color TEXT DEFAULT '#3b82f6',
            os_type TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_connected TIMESTAMP,
            FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE SET NULL
        );

        CREATE INDEX IF NOT EXISTS idx_devices_group ON devices(group_id);
        CREATE INDEX IF NOT EXISTS idx_groups_parent ON groups(parent_id);
        CREATE INDEX IF NOT EXISTS idx_groups_category ON groups(category_id);
    `);

    // Migration: add os_type column to existing databases created before this field existed
    const deviceColumns = queryAll("PRAGMA table_info(devices)");
    if (!deviceColumns.some(c => c.name === 'os_type')) {
        db.run('ALTER TABLE devices ADD COLUMN os_type TEXT');
    }

    saveDb();
}

function queryAll(sql, params = []) {
    const stmt = db.prepare(sql);
    stmt.bind(params);
    const results = [];
    while (stmt.step()) {
        results.push(stmt.getAsObject());
    }
    stmt.free();
    return results;
}

function queryOne(sql, params = []) {
    const results = queryAll(sql, params);
    return results[0] || null;
}

function run(sql, params = []) {
    db.run(sql, params);
    saveDb();
    return db.getRowsModified();
}

function insert(sql, params = []) {
    db.run(sql, params);
    saveDb();
    return queryOne('SELECT last_insert_rowid() as id').id;
}

// Categories
function getAllCategories() {
    return queryAll('SELECT * FROM categories ORDER BY sort_order, name');
}

function getCategory(id) {
    return queryOne('SELECT * FROM categories WHERE id = ?', [id]);
}

function createCategory(name, color = '#6366f1') {
    return insert('INSERT INTO categories (name, color) VALUES (?, ?)', [name, color]);
}

function updateCategory(id, name, color = '#6366f1') {
    run('UPDATE categories SET name = ?, color = ? WHERE id = ?', [name, color, id]);
}

function deleteCategory(id) {
    run('UPDATE groups SET category_id = NULL WHERE category_id = ?', [id]);
    run('DELETE FROM categories WHERE id = ?', [id]);
}

function toggleCategoryCollapsed(id) {
    run('UPDATE categories SET collapsed = NOT collapsed WHERE id = ?', [id]);
}

// Groups
function getAllGroups() {
    return queryAll(`
        SELECT g.*, c.name as category_name
        FROM groups g
        LEFT JOIN categories c ON g.category_id = c.id
        ORDER BY g.name
    `);
}

function getGroupsByCategory(categoryId) {
    if (categoryId === null) {
        return queryAll('SELECT * FROM groups WHERE category_id IS NULL ORDER BY name');
    }
    return queryAll('SELECT * FROM groups WHERE category_id = ? ORDER BY name', [categoryId]);
}

function getGroup(id) {
    return queryOne('SELECT * FROM groups WHERE id = ?', [id]);
}

function createGroup(name, parentId = null, color = '#6366f1', categoryId = null) {
    return insert('INSERT INTO groups (name, parent_id, color, category_id) VALUES (?, ?, ?, ?)',
        [name, parentId, color, categoryId]);
}

function updateGroup(id, name, parentId = null, color = '#6366f1', categoryId = null) {
    run('UPDATE groups SET name = ?, parent_id = ?, color = ?, category_id = ? WHERE id = ?',
        [name, parentId, color, categoryId, id]);
}

function deleteGroup(id) {
    run('UPDATE devices SET group_id = NULL WHERE group_id = ?', [id]);
    run('UPDATE groups SET parent_id = NULL WHERE parent_id = ?', [id]);
    run('DELETE FROM groups WHERE id = ?', [id]);
}

// Devices
function getAllDevices() {
    return queryAll(`
        SELECT d.*, g.name as group_name, g.color as group_color
        FROM devices d
        LEFT JOIN groups g ON d.group_id = g.id
        ORDER BY d.name
    `);
}

function getDevicesByGroup(groupId) {
    if (groupId === null) {
        return queryAll(`
            SELECT d.*, g.name as group_name, g.color as group_color
            FROM devices d
            LEFT JOIN groups g ON d.group_id = g.id
            WHERE d.group_id IS NULL
            ORDER BY d.name
        `);
    }
    return queryAll(`
        SELECT d.*, g.name as group_name, g.color as group_color
        FROM devices d
        LEFT JOIN groups g ON d.group_id = g.id
        WHERE d.group_id = ?
        ORDER BY d.name
    `, [groupId]);
}

function getDevice(id) {
    return queryOne('SELECT * FROM devices WHERE id = ?', [id]);
}

function getDeviceByRustdeskId(rustdeskId, excludeDeviceId = null) {
    if (excludeDeviceId) {
        return queryOne('SELECT * FROM devices WHERE rustdesk_id = ? AND id != ?', [rustdeskId, excludeDeviceId]);
    }
    return queryOne('SELECT * FROM devices WHERE rustdesk_id = ?', [rustdeskId]);
}

function searchDevices(query) {
    const search = `%${query}%`;
    return queryAll(`
        SELECT d.*, g.name as group_name, g.color as group_color
        FROM devices d
        LEFT JOIN groups g ON d.group_id = g.id
        WHERE d.name LIKE ? OR d.rustdesk_id LIKE ? OR d.description LIKE ?
        ORDER BY d.name
    `, [search, search, search]);
}

function createDevice(rustdeskId, name, password = null, description = null, groupId = null, color = '#3b82f6', osType = null) {
    return insert('INSERT INTO devices (rustdesk_id, name, password, description, group_id, color, os_type) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [rustdeskId, name, password, description, groupId, color, osType]);
}

function updateDevice(id, rustdeskId, name, password = null, description = null, groupId = null, color = '#3b82f6', osType = null) {
    run('UPDATE devices SET rustdesk_id = ?, name = ?, password = ?, description = ?, group_id = ?, color = ?, os_type = ? WHERE id = ?',
        [rustdeskId, name, password, description, groupId, color, osType, id]);
}

function deleteDevice(id) {
    run('DELETE FROM devices WHERE id = ?', [id]);
}

function updateLastConnected(id) {
    run("UPDATE devices SET last_connected = datetime('now') WHERE id = ?", [id]);
}

function getAllRustdeskIds() {
    const rows = queryAll('SELECT rustdesk_id FROM devices');
    return new Set(rows.map(r => r.rustdesk_id));
}

function createDeviceFromServer(rustdeskId, name, hostname = null, osInfo = null) {
    let description = osInfo || '';
    if (hostname) {
        description = description ? `${hostname} - ${description}` : hostname;
    }
    return insert('INSERT INTO devices (rustdesk_id, name, description, group_id, color) VALUES (?, ?, ?, NULL, ?)',
        [rustdeskId, name, description, '#9ca3af']);
}

function getUnassignedDevicesCount() {
    const row = queryOne('SELECT COUNT(*) as count FROM devices WHERE group_id IS NULL');
    return row?.count || 0;
}

function exportAll() {
    return {
        categories: queryAll('SELECT * FROM categories'),
        groups: queryAll('SELECT * FROM groups'),
        devices: queryAll('SELECT * FROM devices')
    };
}

function importAll(data) {
    run('DELETE FROM devices');
    run('DELETE FROM groups');
    run('DELETE FROM categories');

    if (data.categories) {
        for (const cat of data.categories) {
            db.run('INSERT INTO categories (id, name, color, collapsed, sort_order, created_at) VALUES (?, ?, ?, ?, ?, ?)',
                [cat.id, cat.name, cat.color, cat.collapsed, cat.sort_order, cat.created_at]);
        }
    }

    if (data.groups) {
        for (const grp of data.groups) {
            db.run('INSERT INTO groups (id, name, parent_id, category_id, color, created_at) VALUES (?, ?, ?, ?, ?, ?)',
                [grp.id, grp.name, grp.parent_id, grp.category_id, grp.color, grp.created_at]);
        }
    }

    if (data.devices) {
        for (const dev of data.devices) {
            db.run('INSERT INTO devices (id, rustdesk_id, password, name, description, group_id, color, os_type, created_at, last_connected) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [dev.id, dev.rustdesk_id, dev.password, dev.name, dev.description, dev.group_id, dev.color, dev.os_type ?? null, dev.created_at, dev.last_connected]);
        }
    }

    saveDb();
}

module.exports = {
    init,
    getAllCategories,
    getCategory,
    createCategory,
    updateCategory,
    deleteCategory,
    toggleCategoryCollapsed,
    getAllGroups,
    getGroupsByCategory,
    getGroup,
    createGroup,
    updateGroup,
    deleteGroup,
    getAllDevices,
    getDevicesByGroup,
    getDevice,
    getDeviceByRustdeskId,
    searchDevices,
    createDevice,
    updateDevice,
    deleteDevice,
    updateLastConnected,
    getAllRustdeskIds,
    createDeviceFromServer,
    getUnassignedDevicesCount,
    exportAll,
    importAll
};
