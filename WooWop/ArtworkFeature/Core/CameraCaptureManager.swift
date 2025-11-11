import Foundation
import AVFoundation
import UIKit
import Photos

/// Lightweight camera capture manager used by RecordVideoView.
/// - Responsibilities:
///   - Request camera & microphone permissions
///   - Configure an AVCaptureSession with video + audio and provide a preview layer
///   - Start/stop the session and start/stop movie recordings
final class CameraCapture: NSObject {
    static let shared = CameraCapture()

    // Notification posted on the main queue after the session has started running.
    static let sessionStartedNotification = Notification.Name("CameraCaptureSessionStarted")
    // Notification posted when a recording finishes. userInfo["fileURL"] = URL
    static let recordingFinishedNotification = Notification.Name("CameraCaptureRecordingFinished")
    // Notification posted when a recording actually begins. userInfo["fileURL"] = URL (may be writable nil until the file is created)
    static let recordingStartedNotification = Notification.Name("CameraCaptureRecordingStarted")

    let session = AVCaptureSession()
    private(set) lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.masksToBounds = true
        layer.videoGravity = .resizeAspectFill
        return layer
    }()

    private let movieOutput = AVCaptureMovieFileOutput()
    private var configured = false
    private var currentOutputURL: URL?

    private override init() {
        super.init()
    }

    /// Request both camera & microphone permissions.
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var cameraGranted = false
        var micGranted = false

        group.enter()
        AVCaptureDevice.requestAccess(for: .video) { granted in
            cameraGranted = granted
            group.leave()
        }

        group.enter()
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            micGranted = granted
            group.leave()
        }

        group.notify(queue: .main) {
            completion(cameraGranted && micGranted)
        }
    }

    /// Configure session inputs/outputs if not already configured.
    func configureSessionIfNeeded() throws {
        guard !configured else { return }

        session.beginConfiguration()
        session.sessionPreset = .high

        // Video input (front camera preferred for listener selfie)
        if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) ?? AVCaptureDevice.default(for: .video) {
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                }
            } catch {
                session.commitConfiguration()
                throw error
            }
        }

        // Audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                }
            } catch {
                session.commitConfiguration()
                throw error
            }
        }

        // Movie file output
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        session.commitConfiguration()
        configured = true
    }

    func startSession() {
        guard !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            // Ensure the app audio session is configured for recording. This reduces
            // FigAudioSession errors on some devices when enabling audio inputs.
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker])
                try audioSession.setActive(true)
            } catch {
                print("Audio session configuration failed: \(error)")
            }

            self.session.startRunning()
            // Notify observers on the main queue that the session is running so UI layers
            // can update their connections (orientation / mirroring) safely.
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: CameraCapture.sessionStartedNotification, object: nil)
            }
        }
    }

    func stopSession() {
        guard session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.stopRunning()
        }
    }

    // MARK: - Recording

    func startRecording() {
        guard !movieOutput.isRecording else { return }

        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileURL = tempDir.appendingPathComponent("wooWop_capture_\(UUID().uuidString).mov")
        currentOutputURL = fileURL
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)
    }

    func stopRecording() {
        guard movieOutput.isRecording else { return }
        movieOutput.stopRecording()
    }
}

extension CameraCapture: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection]) {
        // Notify observers that recording has started on the file URL. Post on main queue
        DispatchQueue.main.async {
            print("Recording started to: \(outputFileURL.path)")
            NotificationCenter.default.post(name: CameraCapture.recordingStartedNotification, object: nil, userInfo: ["fileURL": outputFileURL])
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
            return
        }

        // For now simply keep the file URL available. Later we'll hand this to VideoComposer.
        print("Finished recording to: \(outputFileURL.path)")
        // Post a notification so another component (UI) can perform composition
        // and save the composed result. The notification contains the raw
        // recorded file URL in userInfo["fileURL"].
        NotificationCenter.default.post(name: CameraCapture.recordingFinishedNotification, object: nil, userInfo: ["fileURL": outputFileURL])
    }
}

extension CameraCapture {
    func saveVideoToPhotos(_ fileURL: URL) {
        // Small helper to perform the PHAsset creation once we have authorization.
        let performSave: () -> Void = {
            PHPhotoLibrary.shared().performChanges({
                let req = PHAssetCreationRequest.forAsset()
                req.addResource(with: .video, fileURL: fileURL, options: nil)
            }, completionHandler: { success, error in
                if success {
                    print("Saved video to Photos: \(fileURL.path)")
                    // Optionally remove the temporary file after a successful save
                    try? FileManager.default.removeItem(at: fileURL)
                } else {
                    print("Failed to save video to Photos: \(String(describing: error))")
                }
            })
        }

        if #available(iOS 14, *) {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                switch status {
                case .authorized, .limited:
                    performSave()
                default:
                    print("Photo library add authorization denied: \(status)")
                }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    performSave()
                } else {
                    print("Photo library authorization denied: \(status)")
                }
            }
        }
    }

        /// Static wrapper that delegates to the shared instance helper.
        static func saveVideoToPhotosStatic(_ fileURL: URL) {
            CameraCapture.shared.saveVideoToPhotos(fileURL)
        }
}
