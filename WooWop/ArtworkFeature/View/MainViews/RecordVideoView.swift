import SwiftUI
import AVFoundation

/// A minimal recording UI that shows the album cover as a movable/zoomable background
/// and a camera preview overlay. The recording/composition plumbing is delegated to
/// `VideoComposer` (stubbed for now).
struct RecordVideoView: View {
    @Environment(\.presentationMode) private var presentationMode

    // The media item to use as the background.
    let artworkImage: UIImage?
    let title: String?

    // Gesture state for pan/zoom
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero

    // Recording state
    @State private var isRecording: Bool = false
    @State private var showPreview: Bool = false

    var body: some View {
        ZStack {
            // Background: artwork that can be panned and zoomed
            GeometryReader { geo in
                Color.black
                    .ignoresSafeArea()

                if let img = artworkImage {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(dragGesture())
                        .gesture(magnificationGesture())
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    // placeholder
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
    }

    private func toggleRecord() {
        if isRecording {
            // stop - hand off to composer (stub)
            isRecording = false
            // TODO: actually stop capture and export composed video
            showPreview = true
        } else {
            // start
            isRecording = true
            // TODO: start camera capture
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

// MARK: - CameraPreviewView

/// Lightweight UIViewRepresentable that hosts an AVCaptureVideoPreviewLayer.
struct CameraPreviewView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .black

        // Placeholder preview layer (real AVCaptureSession wiring to be implemented)
        let label = UILabel()
        label.text = "Camera"
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // no-op for now
    }
}

// MARK: - Preview

#if DEBUG
struct RecordVideoView_Previews: PreviewProvider {
    static var previews: some View {
        RecordVideoView(artworkImage: UIImage(systemName: "music.note.list"), title: "Sample Song")
    }
}
#endif
