import Foundation
import Foundation

// Simple debug file logger for simulator runs. Only active in DEBUG builds.
public func debugLog(_ message: String) {
    #if DEBUG
    let ts = ISO8601DateFormatter().string(from: Date())
    let line = "\(ts) DEBUG: \(message)\n"
    let url = URL(fileURLWithPath: "/tmp/wooWop_debug.log")
    if let data = line.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: url.path) {
            if let fh = try? FileHandle(forWritingTo: url) {
                fh.seekToEndOfFile()
                fh.write(data)
                try? fh.close()
            }
        } else {
            try? data.write(to: url)
        }
    }
    #endif
}
