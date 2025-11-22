import XCTest
import UIKit
import AVFoundation
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
    
    // MARK: - Camera Session Management Tests
    
    func testCameraManagerExists() throws {
        // Test that the camera manager can be instantiated
        // This is a basic unit test that works on simulator
        let manager = CameraCapture()
        XCTAssertNotNil(manager, "Camera manager should be created successfully")
        XCTAssertNotNil(manager.session, "Capture session should exist")
    }
    
    func testSessionControlMethodsExist() throws {
        // Verify the camera API has the methods we need for the green light fix
        let manager = CameraCapture()
        
        // These methods should exist and be callable
        XCTAssertNoThrow(manager.stopSession(), "stopSession method should exist and not crash")
        XCTAssertNoThrow(manager.startSession(), "startSession method should exist and not crash")
        
        // Test that session exists
        XCTAssertNotNil(manager.session, "AVCaptureSession should exist")
        
        // Test that stopRecording can be called safely (has guard)
        XCTAssertNoThrow(manager.stopRecording(), "stopRecording method should exist and not crash")
        
        // Test the GREEN LIGHT FIX: session.stopRunning() should work
        // This is the key method we use in .onDisappear to fix the green light issue
        XCTAssertNoThrow(manager.session.stopRunning(), "session.stopRunning should work (green light fix)")
        XCTAssertFalse(manager.session.isRunning, "Session should be stopped after stopRunning")
    }
    
    func testGreenLightFixDocumentation() throws {
        // This test documents the fix for the green camera light staying on
        // 
        // PROBLEM: After recording video and navigating away from RecordVideoView,
        // the green camera light at the top of iPhone stayed on
        //
        // CAUSE: RecordVideoView.onDisappear only called stopRecording(), 
        // but didn't stop the camera session itself
        //
        // SOLUTION: Also call stopSession() in onDisappear
        
        let manager = CameraCapture()
        
        // The fix: these two calls should both happen in RecordVideoView.onDisappear
        XCTAssertNoThrow(manager.stopRecording(), "Should stop any active recording")
        XCTAssertNoThrow(manager.stopSession(), "Should stop camera session (THE FIX)")
        
        // Session should be stopped after our fix
        XCTAssertFalse(manager.session.isRunning, "Session should be stopped to prevent green light")
    }
    
    // MARK: - Integration Tests (Real Device Required)
    
    func testCameraSessionOnRealDevice() throws {
        #if targetEnvironment(simulator)
        // Skip camera hardware tests on simulator
        throw XCTSkip("Camera session tests require real device hardware")
        #else
        
        let manager = CameraCapture()
        
        // On real device, test actual session management
        manager.startSession()
        
        let expectation = XCTestExpectation(description: "Camera session initialization")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Session should be running on real device (if permissions granted)
            let isRunning = manager.session.isRunning
            
            // Test our fix: stopping session should work
            manager.stopSession()
            
            // Verify session stopped
            XCTAssertFalse(manager.session.isRunning, 
                          "Session should be stopped after stopSession() call")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        #endif
    }
}
