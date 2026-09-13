import Foundation
import Network

/// Lightweight embedded HTTP server enabling wireless drag-and-drop music uploads from PC/Mac browser
public final class WiFiTransferServer: ObservableObject {
    public static let shared = WiFiTransferServer()
    
    @Published public var isRunning: Bool = false
    @Published public var serverAddress: String = ""
    @Published public var uploadedFileCount: Int = 0
    
    private var listener: NWListener?
    private let port: NWEndpoint.Port = 8080
    
    private init() {}
    
    /// Starts the Wi-Fi web server
    public func start() {
        guard !isRunning else { return }
        
        do {
            let parameters = NWParameters.tcp
            listener = try NWListener(using: parameters, on: port)
            
            listener?.stateUpdateHandler = { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .ready:
                    DispatchQueue.main.async {
                        self.isRunning = true
                        if let ip = self.getWiFiAddress() {
                            self.serverAddress = "http://\(ip):\(self.port.rawValue)"
                        } else {
                            self.serverAddress = "http://localhost:\(self.port.rawValue)"
                        }
                    }
                case .failed(let error):
                    print("[WiFiTransferServer] Server failed: \(error)")
                    self.stop()
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: .global(qos: .userInitiated))
        } catch {
            print("[WiFiTransferServer] Failed to start listener: \(error)")
        }
    }
    
    /// Stops the Wi-Fi web server
    public func stop() {
        listener?.cancel()
        listener = nil
        DispatchQueue.main.async {
            self.isRunning = false
            self.serverAddress = ""
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        readHTTPData(connection: connection, accumulatedData: Data())
    }
    
    private func readHTTPData(connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            var totalData = accumulatedData
            if let data = data {
                totalData.append(data)
            }
            
            if let requestString = String(data: totalData, encoding: .ascii), requestString.contains("\r\n\r\n") {
                self.processHTTPRequest(connection: connection, requestData: totalData, headerString: requestString)
            } else if !isComplete && error == nil {
                self.readHTTPData(connection: connection, accumulatedData: totalData)
            } else {
                connection.cancel()
            }
        }
    }
    
    private func processHTTPRequest(connection: NWConnection, requestData: Data, headerString: String) {
        let lines = headerString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            connection.cancel()
            return
        }
        
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            connection.cancel()
            return
        }
        
        let method = parts[0]
        let path = parts[1]
        
        if method == "GET" && (path == "/" || path == "/index.html") {
            // Serve Drag & Drop Web Page
            let html = self.generateWebPageHTML()
            let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(html.utf8.count)\r\nConnection: close\r\n\r\n\(html)"
            self.sendResponse(connection: connection, text: response)
        } else if method == "POST" && path == "/upload" {
            // Handle file upload
            self.handleFileUpload(requestData: requestData, headerString: headerString)
            let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{\"status\":\"success\"}"
            self.sendResponse(connection: connection, text: response)
        } else {
            let response = "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
            self.sendResponse(connection: connection, text: response)
        }
    }
    
    private func handleFileUpload(requestData: Data, headerString: String) {
        // Extract boundary
        guard let boundaryRange = headerString.range(of: "boundary=") else { return }
        let boundaryPrefix = String(headerString[boundaryRange.upperBound...]).components(separatedBy: "\r\n").first?.trimmingCharacters(in: .whitespaces) ?? ""
        let boundary = "--" + boundaryPrefix
        
        guard let boundaryData = boundary.data(using: .utf8),
              let headerEndRange = requestData.range(of: "\r\n\r\n".data(using: .utf8)!) else { return }
        
        let bodyData = requestData.subdata(in: headerEndRange.upperBound..<requestData.count)
        
        // Simple filename extraction
        if let bodyString = String(data: bodyData.prefix(1024), encoding: .ascii),
           let filenameRange = bodyString.range(of: "filename=\"") {
            let rest = String(bodyString[filenameRange.upperBound...])
            if let endQuote = rest.range(of: "\"") {
                let filename = String(rest[..<endQuote.lowerBound])
                if !filename.isEmpty {
                    // Extract binary payload
                    let musicDir = LocalFileManager.shared.musicDirectory
                    let destURL = musicDir.appendingPathComponent(filename)
                    
                    // Locate content start and boundary end
                    if let fileContentStart = bodyData.range(of: "\r\n\r\n".data(using: .utf8)!) {
                        let rawContent = bodyData.subdata(in: fileContentStart.upperBound..<bodyData.count)
                        if let endBoundary = rawContent.range(of: boundaryData) {
                            let filePayload = rawContent.subdata(in: 0..<endBoundary.lowerBound - 2)
                            try? filePayload.write(to: destURL)
                            
                            DispatchQueue.main.async {
                                self.uploadedFileCount += 1
                            }
                            Task {
                                await LocalFileManager.shared.scanMusicDirectory()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func sendResponse(connection: NWConnection, text: String) {
        if let data = text.data(using: .utf8) {
            connection.send(content: data, completion: .contentProcessed({ _ in
                connection.cancel()
            }))
        } else {
            connection.cancel()
        }
    }
    
    private func generateWebPageHTML() -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Sonance Wi-Fi Transfer</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0b0f19; color: #fff; display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
                .card { background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.15); border-radius: 24px; padding: 40px; width: 90%; max-width: 500px; text-align: center; box-shadow: 0 20px 40px rgba(0,0,0,0.5); backdrop-filter: blur(20px); }
                h1 { font-size: 28px; margin-bottom: 8px; font-weight: 700; background: linear-gradient(135deg, #a1c4fd, #c2e9fb); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
                p { color: #8fa0b5; margin-bottom: 24px; font-size: 14px; }
                .drop-zone { border: 2px dashed rgba(255,255,255,0.25); border-radius: 16px; padding: 40px 20px; cursor: pointer; transition: all 0.3s ease; }
                .drop-zone:hover, .drop-zone.dragover { border-color: #60a5fa; background: rgba(96,165,250,0.1); }
                .btn { background: #3b82f6; color: white; border: none; padding: 12px 24px; border-radius: 12px; font-size: 15px; font-weight: 600; cursor: pointer; margin-top: 20px; }
                #fileInput { display: none; }
                #status { margin-top: 16px; font-size: 13px; color: #34d399; }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>Sonance Music Transfer</h1>
                <p>Drag and drop audio files (MP3, FLAC, M4A, WAV, LRC) to upload directly to your iPhone</p>
                <div class="drop-zone" id="dropZone">
                    <p style="margin:0;">Drop files here or click to browse</p>
                </div>
                <input type="file" id="fileInput" multiple accept=".mp3,.flac,.m4a,.wav,.aac,.lrc">
                <div id="status"></div>
            </div>
            <script>
                const dropZone = document.getElementById('dropZone');
                const fileInput = document.getElementById('fileInput');
                const status = document.getElementById('status');

                dropZone.onclick = () => fileInput.click();
                dropZone.ondragover = (e) => { e.preventDefault(); dropZone.classList.add('dragover'); };
                dropZone.ondragleave = () => dropZone.classList.remove('dragover');
                dropZone.ondrop = (e) => {
                    e.preventDefault();
                    dropZone.classList.remove('dragover');
                    uploadFiles(e.dataTransfer.files);
                };
                fileInput.onchange = () => uploadFiles(fileInput.files);

                async function uploadFiles(files) {
                    for (let file of files) {
                        status.textContent = 'Uploading ' + file.name + '...';
                        let formData = new FormData();
                        formData.append('file', file, file.name);
                        try {
                            await fetch('/upload', { method: 'POST', body: formData });
                        } catch(err) {
                            console.error(err);
                        }
                    }
                    status.textContent = '✅ All files uploaded successfully!';
                }
            </script>
        </body>
        </html>
        """
    }
    
    private func getWiFiAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" { // Standard Wi-Fi interface on iOS
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
        return address
    }
}
