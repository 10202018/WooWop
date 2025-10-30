import XCTest
import UIKit
@testable import WooWop

final class RecordVideoTests: XCTestCase {
    func testVideoComposerCopiesCameraFileToOutput() throws {
        // Create a temporary "camera" file
        let tmpDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let cameraURL = tmpDir.appendingPathComponent("wooWop_test_camera.mov")
        let outputURL = tmpDir.appendingPathComponent("wooWop_test_output.mov")

        // Ensure no leftover files
        try? FileManager.default.removeItem(at: cameraURL)
        try? FileManager.default.removeItem(at: outputURL)

        // Create a small dummy file to act as the camera recording
        let dummyData = "dummy-video-content".data(using: .utf8)!
        FileManager.default.createFile(atPath: cameraURL.path, contents: dummyData, attributes: nil)
        XCTAssertTrue(FileManager.default.fileExists(atPath: cameraURL.path))

        let artwork = UIImage(systemName: "music.note") ?? UIImage()

        let exp = expectation(description: "VideoComposer completion")

        VideoComposer.compose(cameraVideoURL: cameraURL, artwork: artwork, outputURL: outputURL) { result in
            switch result {
            case .success(let url):
                XCTAssertEqual(url.path, outputURL.path)
                XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
                // Confirm contents were copied
                let out = try? Data(contentsOf: outputURL)
                XCTAssertEqual(out, dummyData)
            case .failure(let err):
                XCTFail("Compose failed: \(err)")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)

        // Cleanup
        try? FileManager.default.removeItem(at: cameraURL)
        try? FileManager.default.removeItem(at: outputURL)
    }
}
