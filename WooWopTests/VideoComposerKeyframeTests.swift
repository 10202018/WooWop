import XCTest
import AVFoundation
import UIKit
@testable import WooWop

final class VideoComposerKeyframeTests: XCTestCase {
    func makeDummyCameraMovie(url: URL, duration: TimeInterval = 1.0, size: CGSize = CGSize(width: 320, height: 240)) throws {
        // Remove existing
        try? FileManager.default.removeItem(at: url)

        let writer = try AVAssetWriter(outputURL: url, fileType: .mov)

        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height)
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
            kCVPixelBufferWidthKey as String: Int(size.width),
            kCVPixelBufferHeightKey as String: Int(size.height),
        ]

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attributes)

        guard writer.canAdd(input) else { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Can't add input"]) }
        writer.add(input)

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        let fps: Int32 = 30
        let frameCount = Int(duration * Double(fps))

        let queue = DispatchQueue(label: "video.writer")
        let sem = DispatchSemaphore(value: 0)

        input.requestMediaDataWhenReady(on: queue) {
            var frame = 0
            while frame < frameCount {
                if input.isReadyForMoreMediaData {
                    autoreleasepool {
                        let time = CMTime(value: CMTimeValue(frame), timescale: fps)
                        var px: CVPixelBuffer?
                        let status = CVPixelBufferCreate(nil, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, nil, &px)
                        if status == kCVReturnSuccess, let buf = px {
                            CVPixelBufferLockBaseAddress(buf, [])
                            // Fill with a color that changes with frame to avoid all-black optimization
                            if let base = CVPixelBufferGetBaseAddress(buf) {
                                let ptr = base.assumingMemoryBound(to: UInt8.self)
                                let color: UInt8 = UInt8((frame * 5) % 255)
                                // ARGB
                                for i in 0..<(Int(size.width)*Int(size.height)) {
                                    let off = i * 4
                                    ptr[off + 0] = 255 // A
                                    ptr[off + 1] = color // R
                                    ptr[off + 2] = color // G
                                    ptr[off + 3] = color // B
                                }
                            }
                            CVPixelBufferUnlockBaseAddress(buf, [])
                            adaptor.append(buf, withPresentationTime: time)
                        }
                    }
                    frame += 1
                }
            }

            input.markAsFinished()
            writer.finishWriting {
                sem.signal()
            }
        }

        // wait
        _ = sem.wait(timeout: .now() + 10)
        if writer.status != .completed {
            throw writer.error ?? NSError(domain: "test", code: 2, userInfo: [NSLocalizedDescriptionKey: "writer failed status:\(writer.status)"])
        }
    }

    func testComposeProducesDebugJSON() throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
        let cameraURL = tmp.appendingPathComponent("wooWop_test_camera_real.mov")
        let outputURL = tmp.appendingPathComponent("wooWop_test_output_real.mov")

        try? FileManager.default.removeItem(at: cameraURL)
        try? FileManager.default.removeItem(at: outputURL)

        // Create a short dummy movie with real video track
        try makeDummyCameraMovie(url: cameraURL, duration: 1.0, size: CGSize(width: 320, height: 240))

        let artwork = UIImage(systemName: "music.note") ?? UIImage()

        // Synthetic keyframes: at 0s center small, at 0.5s moved and larger, at 1.0s final
        let keyframes: [(time: TimeInterval, rect: CGRect)] = [
            (time: 0.0, rect: CGRect(x: 0.35, y: 0.35, width: 0.3, height: 0.3)),
            (time: 0.5, rect: CGRect(x: 0.05, y: 0.05, width: 0.6, height: 0.6)),
            (time: 1.0, rect: CGRect(x: 0.1, y: 0.7, width: 0.2, height: 0.2)),
        ]

        let exp = expectation(description: "compose")

        VideoComposer.compose(cameraVideoURL: cameraURL, artwork: artwork, outputURL: outputURL, pipRectNormalized: nil, pipKeyframes: keyframes) { result in
            switch result {
            case .success(let url):
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
                // Look for /tmp JSON produced by DEBUG logging
                let fm = FileManager.default
                let tmpPath = "/tmp"
                if let files = try? fm.contentsOfDirectory(atPath: tmpPath) {
                    let matches = files.filter { $0.hasPrefix("wooWop_pip_keyframes_") && $0.hasSuffix(".json") }
                    XCTAssertFalse(matches.isEmpty, "Expected debug JSON files in /tmp")
                } else {
                    XCTFail("Cannot list /tmp")
                }
            case .failure(let err):
                XCTFail("Compose failed: \(err)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 30.0)

        // Cleanup
        try? FileManager.default.removeItem(at: cameraURL)
        try? FileManager.default.removeItem(at: outputURL)
    }
}
