// Consulta de presencia (online/offline) directamente al servidor de IDs de
// RustDesk (hbbs, puerto TCP 21115). Es el mismo mecanismo que usa el cliente
// RustDesk para pintar su libreta de direcciones: no requiere credenciales ni
// API de administración, solo conocer los IDs.
//
// Protocolo (rendezvous.proto):
//   RendezvousMessage { online_request = 23 | online_response = 24 }
//   OnlineRequest  { string id = 1; repeated string peers = 2; }
//   OnlineResponse { bytes states = 1; }   // bitmap, bit más significativo = primer ID
// Marco TCP (BytesCodec): cabecera de 1-4 bytes, 2 bits bajos = nº bytes - 1,
// longitud = valor >> 2.

const net = require('net');

const DEFAULT_PORT = 21115;
const BATCH = 300;

const varint = (n) => {
    const out = [];
    while (n > 127) { out.push((n & 127) | 128); n = Math.floor(n / 128); }
    out.push(n);
    return Buffer.from(out);
};

const field = (num, data) => Buffer.concat([varint(num * 8 + 2), varint(data.length), data]);

function frame(buf) {
    const l = buf.length;
    if (l <= 0x3f) return Buffer.concat([Buffer.from([l << 2]), buf]);
    if (l <= 0x3fff) { const v = (l << 2) | 1; return Buffer.concat([Buffer.from([v & 255, v >> 8]), buf]); }
    const v = (l << 2) | 2;
    return Buffer.concat([Buffer.from([v & 255, (v >> 8) & 255, (v >> 16) & 255]), buf]);
}

function readVarint(buf, pos) {
    let result = 0, shift = 0;
    while (pos < buf.length) {
        const b = buf[pos++];
        result += (b & 127) * Math.pow(2, shift);
        if (!(b & 128)) return { value: result, pos };
        shift += 7;
    }
    return null;
}

// Devuelve el payload si el buffer contiene un mensaje completo; null si falta.
function unframe(buf) {
    if (!buf.length) return null;
    const hl = (buf[0] & 3) + 1;
    if (buf.length < hl) return null;
    let v = 0;
    for (let i = 0; i < hl; i++) v += buf[i] * Math.pow(256, i);
    const len = Math.floor(v / 4);
    if (buf.length < hl + len) return null;
    return buf.subarray(hl, hl + len);
}

// Extrae OnlineResponse.states del RendezvousMessage
function parseStates(payload) {
    const tag = readVarint(payload, 0);
    if (!tag || tag.value !== 24 * 8 + 2) throw new Error('Respuesta inesperada del servidor de IDs');
    const len = readVarint(payload, tag.pos);
    const inner = payload.subarray(len.pos, len.pos + len.value);
    const t2 = readVarint(inner, 0);
    if (!t2) return Buffer.alloc(0);
    if (t2.value !== 1 * 8 + 2) return Buffer.alloc(0);
    const l2 = readVarint(inner, t2.pos);
    return inner.subarray(l2.pos, l2.pos + l2.value);
}

function queryBatch(host, port, ids, timeoutMs) {
    return new Promise((resolve, reject) => {
        const req = Buffer.concat([field(1, Buffer.from('rdm')), ...ids.map((i) => field(2, Buffer.from(i)))]);
        const msg = field(23, req);
        const sock = net.connect(port, host);
        let acc = Buffer.alloc(0);
        let done = false;
        const finish = (err, val) => {
            if (done) return;
            done = true;
            sock.destroy();
            err ? reject(err) : resolve(val);
        };
        sock.setTimeout(timeoutMs, () => finish(new Error('Tiempo de espera agotado')));
        sock.on('error', (e) => finish(e));
        sock.on('connect', () => sock.write(frame(msg)));
        sock.on('data', (d) => {
            acc = Buffer.concat([acc, d]);
            const payload = unframe(acc);
            if (payload) {
                try { finish(null, parseStates(payload)); } catch (e) { finish(e); }
            }
        });
        sock.on('close', () => finish(new Error('Conexión cerrada sin respuesta')));
    });
}

// ids: array de IDs RustDesk. Devuelve { id: 'online' | 'offline' }.
// Lanza error si el servidor no responde (el llamador conserva el estado anterior).
async function queryPresence(host, ids, { port = DEFAULT_PORT, timeoutMs = 8000 } = {}) {
    const result = {};
    const clean = [...new Set(ids.filter(Boolean).map(String))];
    for (let start = 0; start < clean.length; start += BATCH) {
        const chunk = clean.slice(start, start + BATCH);
        const states = await queryBatch(host, port, chunk, timeoutMs);
        chunk.forEach((id, k) => {
            const byte = states[Math.floor(k / 8)] || 0;
            result[id] = ((byte >> (7 - (k % 8))) & 1) ? 'online' : 'offline';
        });
    }
    return result;
}

module.exports = { queryPresence, DEFAULT_PORT };
