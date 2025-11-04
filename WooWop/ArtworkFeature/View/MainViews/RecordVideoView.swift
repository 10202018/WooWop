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
                                .gesture(dragGesture())
                                .gesture(magnificationGesture())
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

            // Camera preview as a smaller overlay (PIP)
            VStack {
                Spacer()

                HStack {
                    Spacer()
                    CameraPreviewView()
                        .frame(width: 160, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 6)
                        .padding()
                }
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
        .navigationTitle(title ?? "Record")
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
            VideoComposer.compose(cameraVideoURL: recordedURL, artwork: artworkImage, outputURL: out) { result in
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
                        CameraCapture.shared.startSession()
                        CameraCapture.shared.startRecording()
                        isRecording = true
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
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = lastScale * value
            }
            .onEnded { _ in
                lastScale = scale
            }
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
