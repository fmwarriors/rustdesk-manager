// Instalador de RustDesk para macOS — asistente con interfaz gráfica.
//
// Qué hace:
//   0. Lee el archivo de configuración .rdconfig (doble clic, Escritorio, Descargas, arrastrar o elegir).
//   1. Comprueba el Mac (versión de macOS, Intel o Apple Silicon).
//   2. Busca en GitHub la versión estable más reciente de RustDesk que sea compatible
//      con ese Mac (lee LSMinimumSystemVersion del propio RustDesk.app descargado y,
//      si no encaja, prueba con la versión anterior).
//   3. Pide la contraseña de administrador con el diálogo nativo de macOS e instala.
//   4. Configura el servidor/key/contraseña que vienen en el archivo .rdconfig (el instalador no lleva
//      ningún dato: es el mismo para todos y se puede notarizar una sola vez).
//   5. Guía al usuario para activar los permisos que macOS no permite conceder por script.
//
// Variables de entorno solo para pruebas:
//   RDI_DRY_RUN=1      descarga y verifica, pero NO instala ni toca ninguna configuración
//   RDI_AUTOSTART=1    arranca sin pulsar «Instalar»
//   RDI_SNAPSHOT=dir   genera capturas PNG de cada pantalla y sale

import Cocoa
import SwiftUI

// MARK: - Utilidades

let isDryRun = ProcessInfo.processInfo.environment["RDI_DRY_RUN"] == "1"

let logURL: URL = {
    let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs")
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("RustDeskInstaller.log")
}()

/// Registro de lo que ocurre. Nunca se escriben contraseñas.
func log(_ message: String) {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let line = "[\(f.string(from: Date()))] \(message)\n"
    guard let data = line.data(using: .utf8) else { return }
    if FileManager.default.fileExists(atPath: logURL.path), let h = try? FileHandle(forWritingTo: logURL) {
        h.seekToEndOfFile()
        h.write(data)
        h.closeFile()
    } else {
        try? data.write(to: logURL)
    }
}

/// Escapa un texto para usarlo entre comillas simples en bash.
func shq(_ s: String) -> String {
    return "'" + s.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

@discardableResult
func run(_ exe: String, _ args: [String]) -> (status: Int32, output: String) {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: exe)
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return (-1, "\(error)") }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return (p.terminationStatus, String(data: data, encoding: .utf8) ?? "")
}

func isAppleSilicon() -> Bool {
    var value: Int32 = 0
    var size = MemoryLayout<Int32>.size
    return sysctlbyname("hw.optional.arm64", &value, &size, nil, 0) == 0 && value == 1
}

func parseVersion(_ s: String) -> [Int] {
    return s.split(separator: ".").map { Int($0.filter { $0.isNumber }) ?? 0 }
}

func compareVersions(_ a: [Int], _ b: [Int]) -> Int {
    for i in 0..<max(a.count, b.count) {
        let x = i < a.count ? a[i] : 0
        let y = i < b.count ? b[i] : 0
        if x != y { return x < y ? -1 : 1 }
    }
    return 0
}

func httpGet(_ urlString: String) -> Data? {
    guard let url = URL(string: urlString) else { return nil }
    var req = URLRequest(url: url, timeoutInterval: 15)
    req.setValue("RustDeskInstaller", forHTTPHeaderField: "User-Agent")
    req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    let sem = DispatchSemaphore(value: 0)
    var result: Data?
    URLSession.shared.dataTask(with: req) { data, response, _ in
        if let http = response as? HTTPURLResponse, http.statusCode == 200 { result = data }
        sem.signal()
    }.resume()
    sem.wait()
    return result
}

/// Descarga con progreso.
final class Downloader: NSObject, URLSessionDownloadDelegate {
    private let sem = DispatchSemaphore(value: 0)
    private let destination: URL
    private var failure: String?
    var onProgress: ((Double) -> Void)?

    init(destination: URL) { self.destination = destination }

    /// Devuelve nil si todo fue bien, o un mensaje de error.
    func download(_ url: URL) -> String? {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session.downloadTask(with: url).resume()
        sem.wait()
        session.finishTasksAndInvalidate()
        return failure
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 { onProgress?(Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)) }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let http = downloadTask.response as? HTTPURLResponse, http.statusCode != 200 {
            failure = "HTTP \(http.statusCode)"
            return
        }
        try? FileManager.default.removeItem(at: destination)
        do { try FileManager.default.moveItem(at: location, to: destination) } catch { failure = "\(error)" }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error { failure = error.localizedDescription }
        sem.signal()
    }
}

// MARK: - Archivo de configuración (.rdconfig)
//
// Texto plano, una línea CLAVE=valor, con # para comentarios:
//   NOMBRE=Clínica Raga            (se muestra en pantalla)
//   SERVIDOR=rustdesk.ejemplo.com  (solo el host)
//   KEY=clave_publica_del_servidor
//   CONTRASENA=contraseña_permanente_de_acceso
//   PUSHOVER_TOKEN= / PUSHOVER_USER=   (opcionales)

struct InstallerConfig {
    var name: String
    var server: String
    var key: String
    var password: String
    var pushoverToken: String
    var pushoverUser: String

    /// Devuelve la configuración o un mensaje de error en español.
    static func parse(_ text: String) -> (config: InstallerConfig?, error: String) {
        var values: [String: String] = [:]
        let clean = text.replacingOccurrences(of: "\u{FEFF}", with: "")
        for raw in clean.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            guard let eq = line.firstIndex(of: "=") else { continue }
            let k = line[..<eq].trimmingCharacters(in: .whitespaces).uppercased()
            var v = String(line[line.index(after: eq)...]).trimmingCharacters(in: .whitespaces)
            if v.count >= 2, let f = v.first, let l = v.last, (f == "\"" && l == "\"") || (f == "'" && l == "'") {
                v = String(v.dropFirst().dropLast())
            }
            values[k] = v
        }
        func get(_ names: [String]) -> String {
            for n in names { if let v = values[n], !v.isEmpty { return v } }
            return ""
        }
        var server = get(["SERVIDOR", "SERVER", "RENDEZVOUS_SERVER"])
        let key = get(["KEY", "CLAVE"])
        let password = get(["CONTRASENA", "CONTRASEÑA", "PASSWORD"])

        // Tolerancia: si pegan una URL o un puerto, se queda solo el host.
        server = server.replacingOccurrences(of: "^[A-Za-z]+://", with: "", options: .regularExpression)
        server = server.components(separatedBy: CharacterSet(charactersIn: "/:")).first ?? server

        if server.isEmpty { return (nil, "Falta el SERVIDOR en el archivo de configuración (¿está sin rellenar?).") }
        if server.range(of: "^[A-Za-z0-9.-]+$", options: .regularExpression) == nil {
            return (nil, "El SERVIDOR no es válido: debe ser solo el nombre, por ejemplo rustdesk.midominio.com.")
        }
        if key.isEmpty { return (nil, "Falta la KEY en el archivo de configuración.") }
        if key.range(of: "^[A-Za-z0-9+/=_-]+$", options: .regularExpression) == nil {
            return (nil, "La KEY no es válida: cópiala de nuevo tal cual, sin espacios.")
        }
        if password.isEmpty { return (nil, "Falta la CONTRASENA en el archivo de configuración.") }
        if password.rangeOfCharacter(from: .controlCharacters) != nil {
            return (nil, "La CONTRASENA contiene caracteres no válidos.")
        }
        let name = get(["NOMBRE", "NAME"])
        return (InstallerConfig(name: name.isEmpty ? "tu proveedor de soporte" : name, server: server, key: key,
                                password: password, pushoverToken: get(["PUSHOVER_TOKEN"]),
                                pushoverUser: get(["PUSHOVER_USER"])), "")
    }

    static func load(from url: URL) -> (config: InstallerConfig?, error: String) {
        guard let data = try? Data(contentsOf: url), let text = String(data: data, encoding: .utf8) else {
            return (nil, "No se puede leer el archivo «\(url.lastPathComponent)».")
        }
        return parse(text)
    }

    /// Busca un archivo .rdconfig: incrustado en la app, junto a la app (volumen del DMG),
    /// en el Escritorio o en Descargas (el más reciente que sea válido).
    static func find() -> (config: InstallerConfig?, source: String, error: String) {
        let fm = FileManager.default
        if let embedded = Bundle.main.url(forResource: "embedded", withExtension: "rdconfig") {
            let r = load(from: embedded)
            if let c = r.config { return (c, "incluido en el instalador", "") }
        }
        let home = fm.homeDirectoryForCurrentUser
        let dirs = [Bundle.main.bundleURL.deletingLastPathComponent(),
                    home.appendingPathComponent("Desktop"), home.appendingPathComponent("Downloads")]
        var files: [(url: URL, date: Date)] = []
        for d in dirs {
            let items = (try? fm.contentsOfDirectory(at: d, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
            for u in items where u.pathExtension.lowercased() == "rdconfig" && !u.lastPathComponent.lowercased().contains("plantilla") {
                let date = (try? u.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                files.append((u, date))
            }
        }
        files.sort { $0.date > $1.date }
        var firstError = ""
        for f in files {
            let r = load(from: f.url)
            if let c = r.config { return (c, f.url.lastPathComponent, "") }
            if firstError.isEmpty { firstError = "«\(f.url.lastPathComponent)»: \(r.error)" }
        }
        return (nil, "", firstError)
    }
}

struct InstallError: Error { let message: String }

// MARK: - Modelo / lógica de instalación

enum Phase { case welcome, working, permissions, done, failed }

struct StepItem {
    var title: String
    var state: Int // 0 pendiente, 1 en curso, 2 hecho
}

struct PermissionItem {
    let title: String
    let detail: String
    let anchor: String
}

let permissionItems = [
    PermissionItem(title: "Accesibilidad", detail: "Permite que quien te ayude use el ratón y el teclado.", anchor: "Privacy_Accessibility"),
    PermissionItem(title: "Grabación de pantalla", detail: "Permite que quien te ayude vea tu pantalla.", anchor: "Privacy_ScreenCapture"),
    PermissionItem(title: "Monitorización de entrada", detail: "Permite que RustDesk reconozca las teclas pulsadas.", anchor: "Privacy_ListenEvent")
]

final class Model: ObservableObject {
    @Published var phase: Phase = .welcome
    @Published var steps: [StepItem] = []
    @Published var status = ""
    @Published var progress: Double? = nil
    @Published var rustdeskID = ""
    @Published var version = ""
    @Published var errorText = ""
    @Published var permDone = [false, false, false]
    @Published var config: InstallerConfig?
    @Published var configSource = ""
    @Published var configError = ""
    @Published var dropTargeted = false

    /// Copia fija de la configuración usada durante la instalación (se lee desde otro hilo).
    private var active = InstallerConfig(name: "", server: "", key: "", password: "", pushoverToken: "", pushoverUser: "")

    var supportName: String { return config?.name ?? "tu proveedor de soporte" }

    func findConfig() {
        let r = InstallerConfig.find()
        config = r.config
        configSource = r.source
        configError = r.error
        log("Búsqueda de configuración: \(r.config != nil ? "encontrada (\(r.source))" : "no encontrada \(r.error)")")
    }

    func useConfig(at url: URL) {
        let r = InstallerConfig.load(from: url)
        config = r.config
        configSource = r.config != nil ? url.lastPathComponent : ""
        configError = r.config != nil ? "" : "«\(url.lastPathComponent)»: \(r.error)"
        log("Configuración elegida: \(url.lastPathComponent) → \(r.config != nil ? "válida" : r.error)")
    }

    func chooseConfigFile() {
        let panel = NSOpenPanel()
        panel.title = "Elige el archivo de configuración de RustDesk"
        panel.allowedFileTypes = ["rdconfig", "txt"]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url { useConfig(at: url) }
    }

    private func ui(_ block: @escaping () -> Void) { DispatchQueue.main.async(execute: block) }

    private func setStep(_ index: Int, _ text: String) {
        ui {
            for i in 0..<self.steps.count {
                self.steps[i].state = i < index ? 2 : (i == index ? 1 : 0)
            }
            self.status = text
            self.progress = nil
        }
    }

    func start() {
        guard let cfg = config else { return }
        active = cfg
        steps = [StepItem(title: "Comprobar tu Mac", state: 0),
                 StepItem(title: "Descargar RustDesk", state: 0),
                 StepItem(title: "Instalar y configurar", state: 0),
                 StepItem(title: "Obtener tu ID", state: 0)]
        status = ""
        progress = nil
        errorText = ""
        phase = .working
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.install()
            } catch let e as InstallError {
                log("ERROR: \(e.message)")
                self.ui { self.errorText = e.message; self.phase = .failed }
            } catch {
                log("ERROR: \(error)")
                self.ui { self.errorText = "\(error)"; self.phase = .failed }
            }
        }
    }

    // MARK: Versiones candidatas

    private func candidateVersions(arch: String, os: [Int]) -> [String] {
        var tags: [String] = []
        if let data = httpGet("https://api.github.com/repos/rustdesk/rustdesk/releases?per_page=40"),
           let releases = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            for r in releases {
                guard (r["prerelease"] as? Bool) == false, (r["draft"] as? Bool) == false,
                      let tag = r["tag_name"] as? String,
                      tag.range(of: "^[0-9]+\\.[0-9]+\\.[0-9]+$", options: .regularExpression) != nil,
                      let assets = r["assets"] as? [[String: Any]] else { continue }
                let wanted = "rustdesk-\(tag)-\(arch).dmg"
                if assets.contains(where: { ($0["name"] as? String) == wanted }) { tags.append(tag) }
            }
        }
        log("Versiones encontradas en GitHub: \(tags.prefix(8).joined(separator: ", "))")
        // Versiones conocidas como último recurso (sin API o con límite de peticiones).
        for fallback in ["1.4.9", "1.3.2"] where !tags.contains(fallback) { tags.append(fallback) }
        tags.sort { compareVersions(parseVersion($0), parseVersion($1)) > 0 }
        // En Apple Silicon, RustDesk 1.3.3 y posteriores exigen macOS 12.3 (medido leyendo LSMinimumSystemVersion
        // de cada DMG): se evita descargarlas en equipos anteriores. Si esto cambiase, la comprobación posterior
        // del propio RustDesk.app sigue descartando las versiones incompatibles.
        if arch == "aarch64" && compareVersions(os, [12, 3, 0]) < 0 {
            tags = tags.filter { compareVersions(parseVersion($0), [1, 3, 3]) < 0 }
        }
        return tags
    }

    // MARK: Flujo principal

    private func install() throws {
        let fm = FileManager.default
        let osv = ProcessInfo.processInfo.operatingSystemVersion
        var os = [osv.majorVersion, osv.minorVersion, osv.patchVersion]
        // Solo en pruebas (dry-run): simular otra versión de macOS, p. ej. RDI_FAKE_OS=11.5
        if isDryRun, let fake = ProcessInfo.processInfo.environment["RDI_FAKE_OS"], !fake.isEmpty {
            os = parseVersion(fake)
            while os.count < 3 { os.append(0) }
        }
        let osText = "\(os[0]).\(os[1])" + (os[2] > 0 ? ".\(os[2])" : "")
        let silicon = isAppleSilicon()
        let arch = silicon ? "aarch64" : "x86_64"
        log("Inicio. macOS \(osText), \(arch), dry-run=\(isDryRun)")

        let work = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("rdi-\(UUID().uuidString)")
        try fm.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: work) }

        // 1. Comprobar el Mac
        setStep(0, "Comprobando tu Mac…")
        guard compareVersions(os, [10, 14, 0]) >= 0 else {
            throw InstallError(message: "Este Mac tiene macOS \(osText), que es demasiado antiguo. RustDesk necesita macOS 10.14 o superior.")
        }
        let chip = silicon ? "Apple Silicon" : "Intel"
        ui { self.status = "macOS \(osText) · \(chip)" }

        // 2. Descargar la versión adecuada
        setStep(1, "Buscando la versión de RustDesk compatible con tu Mac…")
        let candidates = candidateVersions(arch: arch, os: os)
        var chosenVersion: String?
        var stagedApp: URL?
        var downloadErrors = 0

        for tag in candidates.prefix(8) {
            setStep(1, "Descargando RustDesk \(tag)…")
            let dmg = work.appendingPathComponent("rustdesk-\(tag).dmg")
            let url = URL(string: "https://github.com/rustdesk/rustdesk/releases/download/\(tag)/rustdesk-\(tag)-\(arch).dmg")!
            let downloader = Downloader(destination: dmg)
            downloader.onProgress = { p in self.ui { self.progress = p } }
            if let err = downloader.download(url) {
                log("Descarga de \(tag) fallida: \(err)")
                downloadErrors += 1
                continue
            }
            ui { self.progress = nil; self.status = "Verificando RustDesk \(tag)…" }

            let mount = work.appendingPathComponent("mnt-\(tag)")
            try fm.createDirectory(at: mount, withIntermediateDirectories: true)
            let attach = run("/usr/bin/hdiutil", ["attach", dmg.path, "-nobrowse", "-readonly", "-noverify", "-mountpoint", mount.path])
            guard attach.status == 0 else {
                log("hdiutil attach falló: \(attach.output)")
                continue
            }
            let app = mount.appendingPathComponent("RustDesk.app")
            func detach() { _ = run("/usr/bin/hdiutil", ["detach", mount.path, "-force"]) }

            let plist = NSDictionary(contentsOf: app.appendingPathComponent("Contents/Info.plist"))
            let minOS = (plist?["LSMinimumSystemVersion"] as? String) ?? "10.14"
            log("RustDesk \(tag) exige macOS \(minOS)")
            if compareVersions(os, parseVersion(minOS)) < 0 {
                log("RustDesk \(tag) descartada: requiere macOS \(minOS) y este Mac tiene \(osText)")
                detach()
                try? fm.removeItem(at: dmg)
                continue
            }
            let sig = run("/usr/bin/codesign", ["--verify", "--deep", "--strict", app.path])
            if sig.status != 0 {
                log("Firma de RustDesk \(tag) no válida: \(sig.output)")
                detach()
                continue
            }
            let stage = work.appendingPathComponent("stage")
            try fm.createDirectory(at: stage, withIntermediateDirectories: true)
            let copy = run("/usr/bin/ditto", [app.path, stage.appendingPathComponent("RustDesk.app").path])
            detach()
            guard copy.status == 0 else { log("ditto falló: \(copy.output)"); continue }
            chosenVersion = tag
            stagedApp = stage.appendingPathComponent("RustDesk.app")
            break
        }

        guard let version = chosenVersion, let staged = stagedApp else {
            if downloadErrors > 0 {
                throw InstallError(message: "No se ha podido descargar RustDesk. Comprueba que este Mac tiene conexión a internet y vuelve a intentarlo.")
            }
            throw InstallError(message: "No hay ninguna versión de RustDesk compatible con macOS \(osText) en este Mac (\(chip)).")
        }
        ui { self.version = version }
        log("Versión elegida: \(version)")

        // 3. Instalar (requiere administrador) y configurar
        setStep(2, "macOS te pedirá tu contraseña para instalar RustDesk…")
        if isDryRun {
            log("DRY RUN: se omite la instalación en /Applications y la configuración")
        } else {
            try privilegedInstall(staged: staged, work: work)
            ui { self.status = "Configurando el servidor…" }
            try writeUserConfig()
        }

        // 4. Obtener el ID
        setStep(3, "Iniciando RustDesk y obteniendo tu ID…")
        var id = ""
        if isDryRun {
            id = "000000000"
            log("DRY RUN completado correctamente (versión \(version))")
        } else {
            _ = run("/usr/bin/open", ["-g", "/Applications/RustDesk.app"])
            for attempt in 1...10 {
                Thread.sleep(forTimeInterval: attempt == 1 ? 4 : 2)
                let r = run("/Applications/RustDesk.app/Contents/MacOS/RustDesk", ["--get-id"])
                let candidate = r.output.trimmingCharacters(in: .whitespacesAndNewlines)
                if candidate.range(of: "^[0-9]{6,12}$", options: .regularExpression) != nil { id = candidate; break }
            }
        }
        log("ID: \(id.isEmpty ? "no disponible" : id)")
        sendPushover(id: id, version: version)

        ui {
            for i in 0..<self.steps.count { self.steps[i].state = 2 }
            self.rustdeskID = id
            self.phase = .permissions
        }
    }

    // MARK: Instalación con privilegios

    private func privilegedInstall(staged: URL, work: URL) throws {
        let script = """
        #!/bin/bash
        set -e
        /usr/bin/pkill -f 'RustDesk.app/Contents/MacOS/RustDesk' 2>/dev/null || true
        sleep 1
        /bin/rm -rf /Applications/RustDesk.app
        /usr/bin/ditto \(shq(staged.path)) /Applications/RustDesk.app
        /usr/bin/xattr -dr com.apple.quarantine /Applications/RustDesk.app 2>/dev/null || true
        /Applications/RustDesk.app/Contents/MacOS/RustDesk --password \(shq(active.password)) >/dev/null 2>&1 || true
        """
        let scriptURL = work.appendingPathComponent("install.sh")
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: scriptURL.path)

        let prompt = "RustDesk Installer necesita permiso para instalar RustDesk en este Mac."
        let apple = "do shell script \"/bin/bash \(scriptURL.path)\" with prompt \"\(prompt)\" with administrator privileges"
        let result = run("/usr/bin/osascript", ["-e", apple])
        log("Instalación privilegiada: estado \(result.status)")
        if result.status != 0 {
            if result.output.contains("-128") || result.output.lowercased().contains("cancel") {
                throw InstallError(message: "Has cancelado la petición de contraseña, así que RustDesk no se ha instalado. Pulsa «Reintentar» cuando quieras continuar.")
            }
            log(result.output)
            throw InstallError(message: "No se pudo completar la instalación. Comprueba que tu usuario es administrador de este Mac y vuelve a intentarlo.")
        }
        guard FileManager.default.fileExists(atPath: "/Applications/RustDesk.app") else {
            throw InstallError(message: "La instalación terminó sin errores pero RustDesk no aparece en Aplicaciones.")
        }
    }

    private func writeUserConfig() throws {
        let fm = FileManager.default
        let dir = fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Preferences/com.carriez.RustDesk")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("RustDesk2.toml")
        if fm.fileExists(atPath: file.path) {
            let stamp = Int(Date().timeIntervalSince1970)
            try? fm.copyItem(at: file, to: dir.appendingPathComponent("RustDesk2.toml.backup-\(stamp)"))
        }
        let toml = """
        rendezvous_server = '\(active.server):21116'
        nat_type = 1
        serial = 0
        unlock_pin = ''
        trusted_devices = ''

        [options]
        key = '\(active.key)'
        relay-server = '\(active.server)'
        custom-rendezvous-server = '\(active.server)'
        direct-server = 'Y'
        direct-access-port = '21118'
        """
        try toml.write(to: file, atomically: true, encoding: .utf8)
        log("Configuración del servidor escrita en \(file.path)")
    }

    private func sendPushover(id: String, version: String) {
        let token = active.pushoverToken, user = active.pushoverUser
        guard !token.isEmpty, !user.isEmpty, !isDryRun else { return }
        let host = Host.current().localizedName ?? ProcessInfo.processInfo.hostName
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm"
        let message = "ID: \(id)\nEquipo: \(host)\nVersión: \(version)\nFecha: \(df.string(from: Date()))"
        _ = run("/usr/bin/curl", ["-s", "-F", "token=\(token)", "-F", "user=\(user)",
                                  "-F", "title=RustDesk instalado: \(host) (\(active.name))",
                                  "-F", "message=\(message)", "https://api.pushover.net/1/messages.json"])
    }

    // MARK: Acciones de la interfaz

    func openPermission(_ item: PermissionItem) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(item.anchor)") {
            NSWorkspace.shared.open(url)
        }
    }

    func openRustDesk() { _ = run("/usr/bin/open", ["/Applications/RustDesk.app"]) }

    func finishPermissions() { phase = .done }

    func copyID() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(rustdeskID, forType: .string)
    }

    func showLog() { NSWorkspace.shared.open(logURL) }
}

// MARK: - Interfaz

extension View {
    /// Intro activa el botón principal (solo macOS 11+; en 10.15 se pulsa con el ratón).
    @ViewBuilder func defaultAction() -> some View {
        if #available(macOS 11.0, *) { self.keyboardShortcut(.defaultAction) } else { self }
    }
}

struct BarView: NSViewRepresentable {
    var progress: Double?

    func makeNSView(context: Context) -> NSProgressIndicator {
        let bar = NSProgressIndicator()
        bar.style = .bar
        bar.minValue = 0
        bar.maxValue = 1
        return bar
    }

    func updateNSView(_ bar: NSProgressIndicator, context: Context) {
        if let p = progress {
            bar.isIndeterminate = false
            bar.stopAnimation(nil)
            bar.doubleValue = p
        } else {
            bar.isIndeterminate = true
            bar.startAnimation(nil)
        }
    }
}

struct NumberRow: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(Color.accentColor).frame(width: 28, height: 28)
                Text(number).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold))
                Text(detail).font(.system(size: 13)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

struct ContentView: View {
    @ObservedObject var model: Model

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Group {
                switch model.phase {
                case .welcome: welcome
                case .working: working
                case .permissions: permissions
                case .done: done
                case .failed: failed
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(RoundedRectangle(cornerRadius: 6)
            .stroke(Color.accentColor, lineWidth: model.dropTargeted ? 4 : 0))
        .onDrop(of: ["public.file-url"], isTargeted: $model.dropTargeted) { providers in
            guard let p = providers.first else { return false }
            p.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                var url: URL?
                if let data = item as? Data { url = URL(dataRepresentation: data, relativeTo: nil) }
                else if let u = item as? URL { url = u }
                if let url = url { DispatchQueue.main.async { model.useConfig(at: url) } }
            }
            return true
        }
    }

    var header: some View {
        HStack(spacing: 16) {
            Image(nsImage: NSApp?.applicationIconImage ?? NSImage())
                .resizable()
                .frame(width: 56, height: 56)
            VStack(alignment: .leading, spacing: 3) {
                Text("Instalación de RustDesk").font(.system(size: 22, weight: .semibold))
                Text("Soporte remoto · \(model.supportName)").font(.system(size: 13)).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 18)
    }

    // Bienvenida
    var welcome: some View {
        Group {
            if model.config != nil { welcomeReady } else { welcomeMissing }
        }
    }

    var welcomeReady: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Vamos a instalar y configurar RustDesk en este Mac para que \(model.supportName) pueda ayudarte a distancia. Solo te llevará un par de minutos.")
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
            NumberRow(number: "1", title: "Preparación automática",
                      detail: "Comprobamos tu Mac y descargamos la versión de RustDesk que es compatible con tu macOS.")
            NumberRow(number: "2", title: "La contraseña de tu Mac",
                      detail: "macOS te la pedirá una vez para poder instalar. Es la misma que usas para iniciar sesión.")
            NumberRow(number: "3", title: "Tres permisos al terminar",
                      detail: "macOS no permite activarlos automáticamente. Te guiaremos paso a paso; sin ellos RustDesk no puede ver ni controlar la pantalla.")
            Spacer()
            HStack {
                Button("Salir") { NSApp.terminate(nil) }
                Text("Configuración: \(model.configSource)").font(.system(size: 11)).foregroundColor(.secondary)
                Button("Usar otro archivo…") { model.chooseConfigFile() }
                Spacer()
                Button("Instalar") { model.start() }.defaultAction()
            }
        }
    }

    var welcomeMissing: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Falta el archivo de configuración")
                .font(.system(size: 18, weight: .semibold))
            Text("Este instalador es igual para todos y no lleva datos de ningún servidor. Necesita el archivo de configuración (.rdconfig) que te ha enviado quien te da soporte.")
                .font(.system(size: 13)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 6) {
                Text("•  Haz doble clic en el archivo .rdconfig, o")
                Text("•  déjalo en el Escritorio o en Descargas y pulsa «Buscar de nuevo», o")
                Text("•  arrástralo a esta ventana, o elígelo con el botón de abajo.")
            }
            .font(.system(size: 13))
            if !model.configError.isEmpty {
                Text(model.configError)
                    .font(.system(size: 13)).foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            HStack {
                Button("Salir") { NSApp.terminate(nil) }
                Spacer()
                Button("Buscar de nuevo") { model.findConfig() }
                Button("Elegir archivo…") { model.chooseConfigFile() }.defaultAction()
            }
        }
    }

    // En curso
    var working: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(0..<model.steps.count, id: \.self) { i in
                HStack(spacing: 12) {
                    Text(model.steps[i].state == 2 ? "✓" : (model.steps[i].state == 1 ? "●" : "○"))
                        .foregroundColor(model.steps[i].state == 2 ? .green : (model.steps[i].state == 1 ? .accentColor : .secondary))
                        .font(.system(size: 15, weight: .bold))
                        .frame(width: 18)
                    Text(model.steps[i].title)
                        .font(.system(size: 15, weight: model.steps[i].state == 1 ? .semibold : .regular))
                        .foregroundColor(model.steps[i].state == 0 ? .secondary : .primary)
                }
            }
            Spacer().frame(height: 6)
            BarView(progress: model.progress).frame(height: 14)
            Text(model.status).font(.system(size: 13)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text("No cierres esta ventana hasta que termine.")
                .font(.system(size: 12)).foregroundColor(.secondary)
        }
    }

    // Permisos
    var permissions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Último paso: activa estos tres permisos")
                .font(.system(size: 16, weight: .semibold))
            Text("RustDesk ya está instalado. macOS exige que seas tú quien active los permisos: pulsa «Abrir», busca RustDesk en la lista y activa su interruptor. Si no aparece, pulsa «+» y elige RustDesk en Aplicaciones.")
                .font(.system(size: 13)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(0..<permissionItems.count, id: \.self) { i in
                HStack(spacing: 12) {
                    Toggle(isOn: Binding(get: { model.permDone[i] }, set: { model.permDone[i] = $0 })) { EmptyView() }
                        .labelsHidden()
                    VStack(alignment: .leading, spacing: 2) {
                        Text(permissionItems[i].title).font(.system(size: 14, weight: .semibold))
                        Text(permissionItems[i].detail).font(.system(size: 12)).foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("Abrir") { model.openPermission(permissionItems[i]) }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
            }
            Text("Si macOS te pide cerrar y reabrir RustDesk tras activar la grabación de pantalla, acepta.")
                .font(.system(size: 12)).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            HStack {
                Button("Abrir RustDesk") { model.openRustDesk() }
                Spacer()
                Button("Lo haré más tarde") { model.finishPermissions() }
                Button("Ya los he activado") { model.finishPermissions() }
                    .defaultAction()
                    .disabled(!model.permDone.allSatisfy { $0 })
            }
        }
    }

    // Terminado
    var done: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("✓ Todo listo").font(.system(size: 22, weight: .semibold)).foregroundColor(.green)
            Text("RustDesk \(model.version) está instalado y conectado al servidor de \(model.supportName).")
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: 6) {
                Text("El ID de este equipo").font(.system(size: 12)).foregroundColor(.secondary)
                Text(model.rustdeskID.isEmpty ? "No disponible (abre RustDesk para verlo)" : model.rustdeskID)
                    .font(.system(size: model.rustdeskID.isEmpty ? 14 : 34, weight: .medium, design: .monospaced))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.06)))
            Text("Si quien te da soporte te lo pide, comunícale este número.")
                .font(.system(size: 13)).foregroundColor(.secondary)
            Spacer()
            HStack {
                Button("Copiar ID") { model.copyID() }.disabled(model.rustdeskID.isEmpty)
                Spacer()
                Button("Cerrar") { NSApp.terminate(nil) }.defaultAction()
            }
        }
    }

    // Error
    var failed: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("No se ha podido completar la instalación")
                .font(.system(size: 18, weight: .semibold)).foregroundColor(.red)
            Text(model.errorText)
                .font(.system(size: 14))
                .fixedSize(horizontal: false, vertical: true)
            Text("Si el problema continúa, envía el registro a quien te da soporte.")
                .font(.system(size: 12)).foregroundColor(.secondary)
            Spacer()
            HStack {
                Button("Ver registro") { model.showLog() }
                Spacer()
                Button("Salir") { NSApp.terminate(nil) }
                Button("Reintentar") { model.start() }.defaultAction()
            }
        }
    }
}

// MARK: - Aplicación

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    let model = Model()
    private var openedFile = false

    /// Doble clic en un archivo .rdconfig (o arrastrarlo al icono de la app).
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        openedFile = true
        model.useConfig(at: URL(fileURLWithPath: filename))
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildMenu()
        let env = ProcessInfo.processInfo.environment
        let args = CommandLine.arguments

        // Comprobación de un archivo desde la terminal: InstaladorRustDesk --check archivo.rdconfig
        if let i = args.firstIndex(of: "--check"), i + 1 < args.count {
            let r = InstallerConfig.load(from: URL(fileURLWithPath: args[i + 1]))
            if let c = r.config { print("OK  nombre=\(c.name)  servidor=\(c.server)"); exit(0) }
            print("ERROR  \(r.error)"); exit(1)
        }

        if let dir = env["RDI_SNAPSHOT"] {
            snapshots(into: dir)
            NSApp.terminate(nil)
            return
        }

        if !openedFile { model.findConfig() }

        let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                         styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        w.title = "Instalar RustDesk"
        w.contentView = NSHostingView(rootView: ContentView(model: model))
        w.center()
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = w

        if env["RDI_AUTOSTART"] == "1" { model.start() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return true }

    private func buildMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Salir de Instalar RustDesk", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        NSApp.mainMenu = main
    }

    /// Genera una imagen PNG de cada pantalla (para revisión visual, sin mostrar ventanas).
    private func snapshots(into dir: String) {
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let cases: [(String, (Model) -> Void)] = [
            ("1-bienvenida", { _ in }),
            ("1b-sin-archivo", { m in m.config = nil; m.configError = "«config.rdconfig»: Falta la CONTRASENA en el archivo de configuración." }),
            ("2-instalando", { m in
                m.steps = [StepItem(title: "Comprobar tu Mac", state: 2), StepItem(title: "Descargar RustDesk", state: 1),
                           StepItem(title: "Instalar y configurar", state: 0), StepItem(title: "Obtener tu ID", state: 0)]
                m.status = "Descargando RustDesk 1.5.3…"; m.progress = 0.42; m.phase = .working }),
            ("3-permisos", { m in m.permDone = [true, false, false]; m.rustdeskID = "123456789"; m.phase = .permissions }),
            ("4-listo", { m in m.rustdeskID = "123456789"; m.version = "1.5.3"; m.phase = .done }),
            ("5-error", { m in m.errorText = "Has cancelado la petición de contraseña, así que RustDesk no se ha instalado. Pulsa «Reintentar» cuando quieras continuar."; m.phase = .failed })
        ]
        for (name, setup) in cases {
            let m = Model()
            m.config = InstallerConfig(name: "Clínica Ejemplo", server: "rustdesk.ejemplo.com", key: "x", password: "x", pushoverToken: "", pushoverUser: "")
            m.configSource = "Clínica Ejemplo.rdconfig"
            setup(m)
            let view = NSHostingView(rootView: ContentView(model: m))
            view.frame = NSRect(x: 0, y: 0, width: 600, height: 500)
            let win = NSWindow(contentRect: view.frame, styleMask: [.titled], backing: .buffered, defer: false)
            win.contentView = view
            view.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
            if let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) {
                view.cacheDisplay(in: view.bounds, to: rep)
                if let png = rep.representation(using: .png, properties: [:]) {
                    try? png.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
                }
            }
        }
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
