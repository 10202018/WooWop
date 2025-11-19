import SwiftUI
import AVFoundation
import Photos

/// A minimal recording UI that shows the album cover as a movable/zoomable background
/// and a camera preview overlay. The recording/composition plumbing is delegated to
/// `VideoComposer` (stubbed for now).
struct RecordVideoView: View {
    @Environment(\.presentationMode) private var presentationMode

    // The media item to use as the background (URL loaded async).
    let artworkURL: URL?
    let title: String?

    // Gesture state for pan/zoom
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    // PIP interactive state (position only)
    @State private var pipOffset: CGSize = .zero
    @State private var pipLastOffset: CGSize = .zero
    @State private var canvasSize: CGSize = .zero
    
    // Camera zoom state
    @State private var cameraZoomFactor: CGFloat = 1.0
    @State private var lastCameraZoomFactor: CGFloat = 1.0
    
    // Zoom thresholds
    private let maxZoomIn: CGFloat = 3.0 // Maximum zoom in before stopping
    private let minZoomOut: CGFloat = 0.5 // Minimum camera zoom level
    
    // Keyframes captured while recording: (time since recording start, normalized rect)
    @State private var pipKeyframes: [(time: TimeInterval, rect: CGRect)] = []
    @State private var recordingStartTime: Date?

    // Recording state
    @State private var isRecording: Bool = false
    @State private var showPreview: Bool = false
    // Composition state
    @State private var isComposing: Bool = false
    @State private var recordingObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            // Background: artwork that can be panned and zoomed
            GeometryReader { geo in
                Color.black
                    .ignoresSafeArea()

                if let url = artworkURL {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .scaleEffect(scale)
                                .offset(offset)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray)
                                .overlay(Text("Loading artwork...").foregroundColor(.white))
                        }
                    }
                } else {
                    // placeholder when no URL
                    Rectangle()
                        .fill(Color.gray)
                        .overlay(Text("No artwork").foregroundColor(.white))
                }
            }

            // Camera preview as a movable/scalable overlay (PIP)
            GeometryReader { geo in
                // capture canvas size for normalized rect calculation
                Color.clear.onAppear { canvasSize = geo.size }
                Color.clear.onChange(of: geo.size) { new in canvasSize = new }

                // Background gesture overlay - captures gestures for background positioning
                // but allows PIP to handle its own gestures
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(dragGesture())
                    .gesture(magnificationGesture())

                // compute base PIP size and initial anchored center (lower-right)
                let baseSize = CGSize(width: 160, height: 240)
                let margin: CGFloat = 24
                let initialCenterX = geo.size.width - margin - baseSize.width / 2
                let initialCenterY = geo.size.height - margin - baseSize.height / 2

                CameraPreviewView()
                    .frame(width: baseSize.width, height: baseSize.height)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 6)
                    .position(x: initialCenterX + pipOffset.width, y: initialCenterY + pipOffset.height)
                    .gesture(dragPIPGesture())
                    .gesture(pipZoomGesture())
                    .padding()
            }

            // Controls
            VStack {
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding()

                Spacer()

                HStack {
                    Spacer()
                    
                    // Zoom controls
                    VStack(spacing: 12) {
                        Button(action: { 
                            let newZoom = min(cameraZoomFactor * 1.2, maxZoomIn)
                            if newZoom > cameraZoomFactor {
                                CameraCapture.shared.setZoomFactor(newZoom)
                                cameraZoomFactor = newZoom
                            }
                        }) {
                            Image(systemName: "plus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Button(action: { 
                            let newZoom = max(cameraZoomFactor / 1.2, minZoomOut)
                            if newZoom != cameraZoomFactor {
                                CameraCapture.shared.setZoomFactor(newZoom)
                                cameraZoomFactor = newZoom
                            }
                        }) {
                            Image(systemName: "minus.magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.trailing, 20)

                    Button(action: toggleRecord) {
                        Circle()
                            .fill(isRecording ? Color.red : Color.white)
                            .frame(width: 68, height: 68)
                            .overlay(Image(systemName: isRecording ? "stop.fill" : "record.circle").font(.title).foregroundColor(isRecording ? .white : .red))
                    }
                    .padding(.bottom, 32)

                    Spacer()
                }
            }
        }
    // Hide the navigation bar entirely; we don't want any title overlaying the background artwork
    .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Observe finished recording and kick off compose+save flow
            recordingObserver = NotificationCenter.default.addObserver(forName: CameraCapture.recordingFinishedNotification, object: nil, queue: .main) { note in
                handleRecordingFinished(note)
            }
        }
        .onDisappear {
            if let obs = recordingObserver {
                NotificationCenter.default.removeObserver(obs)
                recordingObserver = nil
            }
        }
        // Simple composing progress overlay
        .overlay(Group {
            if isComposing {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView("Composing video…")
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
            }
        })
    }

    private func handleRecordingFinished(_ notification: Notification) {
        guard let recordedURL = notification.userInfo?["fileURL"] as? URL else { return }
        isComposing = true

        func composeWithArtwork(_ artworkImage: UIImage) {
            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            let out = tempDir.appendingPathComponent("wooWop_composed_\(UUID().uuidString).mov")
            // Compute normalized PIP rect/keyframes from captured state. If we recorded
            // keyframes during the recording, forward them to the composer so the
            // exported video mirrors the PIP movement over time. Otherwise, send the
            // single final normalized rect.
            var normRect: CGRect? = nil
            if canvasSize.width > 0 && canvasSize.height > 0 {
                let baseSize = CGSize(width: 160, height: 240)
                // The exported PIP window should remain the base window size.
                // `pipScale` controls the internal zoom of the preview content
                // in the live UI, but the composer expects the normalized rect
                // to represent the window bounds. Do not multiply by `pipScale`.
                let currentWidth = baseSize.width
                let currentHeight = baseSize.height
                let margin: CGFloat = 24
                let initialCenterX = canvasSize.width - margin - baseSize.width / 2
                let initialCenterY = canvasSize.height - margin - baseSize.height / 2
                let centerX = initialCenterX + pipOffset.width
                let centerY = initialCenterY + pipOffset.height
                let originX = centerX - (currentWidth / 2)
                let originY = centerY - (currentHeight / 2)
                let nx = originX / canvasSize.width
                let ny = originY / canvasSize.height
                let nw = currentWidth / canvasSize.width
                let nh = currentHeight / canvasSize.height
                normRect = CGRect(x: max(0, nx), y: max(0, ny), width: max(0, nw), height: max(0, nh))
            }

                // If we captured any keyframes while recording, use them. Otherwise pass
                // a single final rect.
                let keyframesToSend: [(time: TimeInterval, rect: CGRect)]? = pipKeyframes.isEmpty ? nil : pipKeyframes

            // Convert UI background positioning to normalized coordinates
            let backgroundOffsetNormalized = CGPoint(
                x: canvasSize.width > 0 ? offset.width / canvasSize.width : 0,
                y: canvasSize.height > 0 ? offset.height / canvasSize.height : 0
            )

            print("🖼️ BACKGROUND DEBUG - Canvas size: \(canvasSize)")
            print("🖼️ BACKGROUND DEBUG - UI offset: \(offset)")
            print("🖼️ BACKGROUND DEBUG - UI scale: \(scale)")
            print("🖼️ BACKGROUND DEBUG - Normalized offset: \(backgroundOffsetNormalized)")

            VideoComposer.compose(
                cameraVideoURL: recordedURL, 
                artwork: artworkImage, 
                outputURL: out, 
                pipRectNormalized: normRect, 
                pipKeyframes: keyframesToSend,
                backgroundScale: scale,
                backgroundOffset: backgroundOffsetNormalized
            ) { result in
                DispatchQueue.main.async {
                    isComposing = false
                }
                switch result {
                case .success(let composedURL):
                    // Save composed movie to Photos
                    CameraCapture.saveVideoToPhotosStatic(composedURL)
                    print("Composed video exported: \(composedURL.path)")
                case .failure(let err):
                    print("Video composition failed: \(err)")
                }
            }
        }

        // Load artwork image (async). Fall back to a placeholder if unavailable.
        if let artURL = artworkURL {
            let task = URLSession.shared.dataTask(with: artURL) { data, _, _ in
                if let d = data, let img = UIImage(data: d) {
                    composeWithArtwork(img)
                } else {
                    composeWithArtwork(UIImage(systemName: "photo") ?? UIImage())
                }
            }
            task.resume()
        } else {
            composeWithArtwork(UIImage(systemName: "photo") ?? UIImage())
        }
    }

    private func toggleRecord() {
        if isRecording {
            // stop recording
            CameraCapture.shared.stopRecording()
            isRecording = false
            showPreview = true
            // finalize recording keyframes by stamping the final state
            if let start = recordingStartTime, canvasSize.width > 0 {
                let t = Date().timeIntervalSince(start)
                if let r = currentNormalizedRect() {
                    pipKeyframes.append((time: t, rect: r))
                }
            }
        } else {
            // Request permissions then start session + recording
            CameraCapture.shared.requestPermissions { granted in
                DispatchQueue.main.async {
                    guard granted else {
                        // permission denied - open settings or show UI in future
                        isRecording = false
                        return
                    }

                    do {
                        try CameraCapture.shared.configureSessionIfNeeded()
                        // Start the session. Starting recording immediately can fail
                        // if the session hasn't fully started; wait for the
                        // CameraCapture.sessionStartedNotification if needed.
                        CameraCapture.shared.startSession()

                        if CameraCapture.shared.session.isRunning {
                            // Session already running: start recording immediately and wait for
                            // the movie output to confirm recording has actually started
                            CameraCapture.shared.startRecording()

                            var recObs: NSObjectProtocol?
                            recObs = NotificationCenter.default.addObserver(forName: CameraCapture.recordingStartedNotification, object: nil, queue: .main) { note in
                                // Recording has started for real; flip UI state and stamp time
                                isRecording = true
                                recordingStartTime = Date()
                                pipKeyframes.removeAll()
                                if let r = currentNormalizedRect() { pipKeyframes.append((time: 0.0, rect: r)) }
                                if let o = recObs { NotificationCenter.default.removeObserver(o) }
                            }
                        } else {
                            // Observe one-shot session started notification then begin recording.
                            // We'll also observe the recording-started notification before
                            // updating UI so we don't show the red indicator until the file
                            // output is actually writing.
                            var obs: NSObjectProtocol?
                            obs = NotificationCenter.default.addObserver(forName: CameraCapture.sessionStartedNotification, object: nil, queue: .main) { _ in
                                CameraCapture.shared.startRecording()

                                var recObs: NSObjectProtocol?
                                recObs = NotificationCenter.default.addObserver(forName: CameraCapture.recordingStartedNotification, object: nil, queue: .main) { note in
                                    isRecording = true
                                    recordingStartTime = Date()
                                    pipKeyframes.removeAll()
                                    if let r = currentNormalizedRect() { pipKeyframes.append((time: 0.0, rect: r)) }
                                    if let o = recObs { NotificationCenter.default.removeObserver(o) }
                                }

                                if let o = obs { NotificationCenter.default.removeObserver(o) }
                            }
                        }
                    } catch {
                        // configuration failed
                        isRecording = false
                        print("Camera session configuration failed: \(error)")
                    }
                }
            }
        }
    }

    private func dragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(width: lastOffset.width + value.translation.width, height: lastOffset.height + value.translation.height)
                print("🖼️ BACKGROUND DEBUG - Drag offset: \(offset)")
            }
            .onEnded { _ in
                lastOffset = offset
                print("🖼️ BACKGROUND DEBUG - Final drag offset: \(offset)")
            }
    }

    private func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = lastScale * value
                print("🖼️ BACKGROUND DEBUG - Magnification scale: \(scale)")
            }
            .onEnded { _ in
                lastScale = scale
                print("🖼️ BACKGROUND DEBUG - Final scale: \(scale)")
            }
    }

    // MARK: - PIP gestures
    private func dragPIPGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                pipOffset = CGSize(width: pipLastOffset.width + value.translation.width, height: pipLastOffset.height + value.translation.height)
                // capture keyframe while recording
                if isRecording, let start = recordingStartTime, canvasSize.width > 0 {
                    let t = Date().timeIntervalSince(start)
                    if let r = currentNormalizedRect() {
                        // avoid duplicating identical last frame
                if pipKeyframes.last?.rect != r {
                    pipKeyframes.append((time: t, rect: r))
                        }
                    }
                }
            }
            .onEnded { _ in
                pipLastOffset = pipOffset
            }
    }

    // Zooming has been removed for PiP; only repositioning remains.
    
    // MARK: - PIP Zoom Gesture
    
    private func pipZoomGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let scaleDelta = value / lastCameraZoomFactor
                let newCameraZoom = cameraZoomFactor * scaleDelta
                
                // Handle both zoom in and zoom out with camera zoom only
                // Clamp to device limits and our min/max zoom range
                let clampedZoom = max(minZoomOut, min(maxZoomIn, newCameraZoom))
                
                if clampedZoom != cameraZoomFactor {
                    CameraCapture.shared.setZoomFactor(clampedZoom)
                    lastCameraZoomFactor = value
                }
                
                // Capture keyframe while recording
                if isRecording, let start = recordingStartTime, canvasSize.width > 0 {
                    let t = Date().timeIntervalSince(start)
                    if let r = currentNormalizedRect() {
                        if pipKeyframes.last?.rect != r {
                            pipKeyframes.append((time: t, rect: r))
                        }
                    }
                }
            }
            .onEnded { _ in
                lastCameraZoomFactor = 1.0
                cameraZoomFactor = CameraCapture.shared.currentZoomFactor
            }
    }

    private func currentNormalizedRect() -> CGRect? {
        guard canvasSize.width > 0 && canvasSize.height > 0 else { return nil }
        let baseSize = CGSize(width: 160, height: 240)
        // Keep the window frame at the base size - no scaling
        let currentWidth = baseSize.width
        let currentHeight = baseSize.height
        let margin: CGFloat = 24
        let initialCenterX = canvasSize.width - margin - baseSize.width / 2
        let initialCenterY = canvasSize.height - margin - baseSize.height / 2
        let centerX = initialCenterX + pipOffset.width
        let centerY = initialCenterY + pipOffset.height
        let originX = centerX - (currentWidth / 2)
        let originY = centerY - (currentHeight / 2)
        let nx = originX / canvasSize.width
        let ny = originY / canvasSize.height
        let nw = currentWidth / canvasSize.width
        let nh = currentHeight / canvasSize.height
        return CGRect(x: max(0, nx), y: max(0, ny), width: max(0, nw), height: max(0, nh))
    }
}

// MARK: - PreviewContainer & CameraPreviewView

/// A UIView container that keeps its preview layer sized to its bounds reliably.
final class PreviewContainerView: UIView {
    let previewLayer: AVCaptureVideoPreviewLayer

    init(session: AVCaptureSession) {
        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        super.init(frame: .zero)
        backgroundColor = .black
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.masksToBounds = true
        previewLayer.needsDisplayOnBoundsChange = true
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep preview layer in sync with view bounds
        previewLayer.frame = bounds

        // If a connection exists, ensure orientation and mirroring are applied on the main thread
        if let connection = previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }

            if connection.isVideoMirroringSupported {
                if let deviceInput = CameraCapture.shared.session.inputs.compactMap({ $0 as? AVCaptureDeviceInput }).first,
                   deviceInput.device.position == .front {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = true
                } else {
                    connection.automaticallyAdjustsVideoMirroring = false
                    connection.isVideoMirrored = false
                }
            }
        }
    }
}

/// Lightweight UIViewRepresentable that hosts an AVCaptureVideoPreviewLayer inside a container.
struct CameraPreviewView: UIViewRepresentable {
    class Coordinator {
        var containerView: PreviewContainerView?
        var sessionStartedObserver: NSObjectProtocol?
        deinit {
            if let obs = sessionStartedObserver {
                NotificationCenter.default.removeObserver(obs)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let container = PreviewContainerView(session: CameraCapture.shared.session)
        context.coordinator.containerView = container
        // Start the session if permissions are already granted and configure it.
        // Start the session if permissions are already granted and configure it.
        CameraCapture.shared.requestPermissions { granted in
            if granted {
                DispatchQueue.global(qos: .userInitiated).async {
                    do {
                        try CameraCapture.shared.configureSessionIfNeeded()
                        CameraCapture.shared.startSession()
                    } catch {
                        print("Failed to configure camera: \(error)")
                    }
                }
            }
        }

        // Observe session-started to update connection properties once the session is running
        context.coordinator.sessionStartedObserver = NotificationCenter.default.addObserver(forName: CameraCapture.sessionStartedNotification, object: nil, queue: .main) { _ in
            // Force a layout pass so PreviewContainerView.layoutSubviews runs and applies connection settings
            container.setNeedsLayout()
            container.layoutIfNeeded()
        }

        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Trigger a layout/update to ensure preview layer matches current bounds
        uiView.setNeedsLayout()
    }
}

// MARK: - Preview

#if DEBUG
struct RecordVideoView_Previews: PreviewProvider {
    static var previews: some View {
        // Preview with no artwork URL (placeholder will show)
        RecordVideoView(artworkURL: nil, title: "Sample Song")
    }
}
#endif
