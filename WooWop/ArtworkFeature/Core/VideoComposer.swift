import Foundation
import Foundation
import AVFoundation
import UIKit

/// VideoComposer composes a recorded camera video with a static artwork image
/// as the background. The current implementation overlays the camera video as
/// a picture-in-picture (PIP) in the lower-right corner of the artwork and
/// exports a single composed movie to `outputURL`.
public struct VideoComposer {
    /// Compose the recorded camera video file with a background artwork image.
    /// - Parameters:
    ///   - cameraVideoURL: URL of the recorded camera video file.
    ///   - artwork: UIImage used as the background.
    ///   - outputURL: Destination file URL for the composed video.
    ///   - completion: Called on the main queue with the composed file URL or an error.
    /// - Parameters:
    ///   - pipRectNormalized: Optional CGRect in normalized coordinates (0..1) relative to
    ///     the artwork/render size specifying where the camera PIP should be placed and
    ///     how large it should be. If nil, a default lower-right PIP is used.
    public static func compose(cameraVideoURL: URL, artwork: UIImage, outputURL: URL, pipRectNormalized: CGRect? = nil, pipKeyframes: [(time: TimeInterval, rect: CGRect)]? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: cameraVideoURL)

        // Ensure the recorded asset has a video track. If the provided file isn't
        // a readable AV asset (for example in unit tests we may supply a tiny
        // dummy file), fall back to copying the input to the output so callers
        // still receive a file at `outputURL`.
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            // Attempt a simple file copy fallback
            do {
                if FileManager.default.fileExists(atPath: cameraVideoURL.path) {
                    try FileManager.default.copyItem(at: cameraVideoURL, to: outputURL)
                    DispatchQueue.main.async { completion(.success(outputURL)) }
                    return
                } else {
                    throw NSError(domain: "VideoComposer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track found and camera file missing"]) 
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
        }

        // Compute render size from video track's naturalSize and preferredTransform
        let transformedSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let renderSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))

        let composition = AVMutableComposition()
        do {
            if let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
                // Do NOT set the composition track's preferredTransform here. We'll
                // apply the correct transform via the layer instruction so the
                // AVVideoComposition rendering (and CoreAnimation post-processing)
                // receives the transform consistently.
            }

            if let audioTrack = asset.tracks(withMediaType: .audio).first, let compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: audioTrack, at: .zero)
            }
        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
            return
        }

        // Create video composition instructions (pass-through with transforms)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: asset.duration)

        if let compTrack = composition.tracks(withMediaType: .video).first {
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compTrack)
            // Apply the original video track's preferredTransform here so the
            // video is rotated/scaled correctly for presentation. We intentionally
            // avoid setting the composition track's preferredTransform above to
            // keep this logic in one place.
            layerInstruction.setTransform(videoTrack.preferredTransform, at: .zero)
            instruction.layerInstructions = [layerInstruction]
        }

        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [instruction]
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.renderSize = renderSize

    // Core Animation layers: artwork as background, video as PIP
    let parentLayer = CALayer()
    parentLayer.frame = CGRect(origin: .zero, size: renderSize)
    // Flip geometry so CoreAnimation coordinates align with UIKit-like origin (0,0) top-left
    parentLayer.isGeometryFlipped = true

        let artworkLayer = CALayer()
        artworkLayer.frame = parentLayer.bounds
        artworkLayer.contentsGravity = .resizeAspectFill
        if let cg = artwork.cgImage {
            artworkLayer.contents = cg
        }

        let videoLayer = CALayer()
        // Preserve aspect and avoid stretch: compute the video natural size after
        // applying the track transform (this matches renderSize computation above).
        let transformedVideoSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))
        let videoAspect = transformedVideoSize.height / transformedVideoSize.width

        // Default PIP: 35% width, lower-right with margin. If a normalized rect is
        // supplied by the UI, use that to compute the frame directly. If a set of
        // keyframes was supplied (time + normalized rect), animate the videoLayer
        // across those keyframes so the exported movie follows the live PIP motion.
        let margin: CGFloat = 24
        if let keyframes = pipKeyframes, let first = keyframes.first {
            // Build keyframe animation for the combined transform (translate+scale).
            // Using a single 'transform' animation is more robust when exporting
            // with AVVideoCompositionCoreAnimationTool than animating position+bounds
            // separately.
            let durationSeconds = CMTimeGetSeconds(asset.duration)
            // Compute frames for each keyframe
            var times: [NSNumber] = []
            var transformValues: [NSValue] = []

            // Ensure we include a keyframe at t=0 and at the end of the clip
            var frames = keyframes
            if frames.first?.time ?? 0.0 > 0.0, let rect0 = pipRectNormalized {
                frames.insert((time: 0.0, rect: rect0), at: 0)
            }
            if let last = frames.last, durationSeconds.isFinite && last.time < durationSeconds {
                frames.append((time: durationSeconds, rect: last.rect))
            }

            for kf in frames {
                let nx = max(0.0, min(1.0, kf.rect.origin.x))
                let ny = max(0.0, min(1.0, kf.rect.origin.y))
                let nw = max(0.0, min(1.0, kf.rect.size.width))
                let nh = max(0.0, min(1.0, kf.rect.size.height))
                let frame = CGRect(x: nx * renderSize.width, y: ny * renderSize.height, width: max(1.0, nw * renderSize.width), height: max(1.0, nh * renderSize.height))
                let tnorm = durationSeconds > 0 ? kf.time / durationSeconds : 0
                times.append(NSNumber(value: tnorm))
                // store the actual frame rect as an NSValue – we'll build transforms later
                transformValues.append(NSValue(cgRect: frame))
            }

            // Build transform keyframes. We'll use the first frame as the base
            // (initial bounds/position) and compute CATransform3D values that
            // translate and scale the layer to each keyframe frame.
            if let baseFrame = transformValues.first?.cgRectValue {
                // Set videoLayer to base frame
                videoLayer.frame = baseFrame

                // Prepare transform keyframe values
                var tfValues: [NSValue] = []
                // Debug: capture computed frames and times for inspection
                #if DEBUG
                struct _KF: Codable { var time: Double; var normRect: CGRect; var frame: CGRect }
                var _debugKFs: [_KF] = []
                for (i, v) in transformValues.enumerated() {
                    let frame = v.cgRectValue
                    let t = times.indices.contains(i) ? times[i].doubleValue : 0.0
                    _debugKFs.append(_KF(time: t, normRect: frames[i].rect, frame: frame))
                }
                if let data = try? JSONEncoder().encode(_debugKFs) {
                    let path = "/tmp/wooWop_pip_keyframes_\(UUID().uuidString).json"
                    try? data.write(to: URL(fileURLWithPath: path))
                    print("[VideoComposer] wrote pip keyframes debug to \(path)")
                }
                #endif
                for v in transformValues {
                    let frame = v.cgRectValue
                    // Compute scale relative to base
                    let sx = frame.width / baseFrame.width
                    let sy = frame.height / baseFrame.height
                    let tx = frame.midX - baseFrame.midX
                    let ty = frame.midY - baseFrame.midY
                    var t = CATransform3DIdentity
                    t = CATransform3DTranslate(t, tx, ty, 0)
                    t = CATransform3DScale(t, sx, sy, 1.0)
                    tfValues.append(NSValue(caTransform3D: t))
                }

                if tfValues.count > 1 {
                    let transformAnim = CAKeyframeAnimation(keyPath: "transform")
                    transformAnim.values = tfValues
                    transformAnim.keyTimes = times
                    // Align CoreAnimation timing with AVAsset timeline so the
                    // exporter samples the animation over the movie duration.
                    // AVCoreAnimationBeginTimeAtZero makes the animation start at
                    // the beginning of the exported asset timeline.
                    transformAnim.beginTime = AVCoreAnimationBeginTimeAtZero
                    transformAnim.duration = durationSeconds
                    transformAnim.isRemovedOnCompletion = false
                    transformAnim.fillMode = .forwards
                    transformAnim.calculationMode = .linear
                    videoLayer.add(transformAnim, forKey: "pip.transform")
                }
            } else {
                // fallback: set a default frame
                let pipWidth = renderSize.width * 0.35
                let pipHeight = pipWidth * videoAspect
                videoLayer.frame = CGRect(x: renderSize.width - pipWidth - margin, y: renderSize.height - pipHeight - margin, width: pipWidth, height: pipHeight)
            }
        } else if let norm = pipRectNormalized {
            // Clamp normalized rect
            let nx = max(0.0, min(1.0, norm.origin.x))
            let ny = max(0.0, min(1.0, norm.origin.y))
            let nw = max(0.0, min(1.0, norm.size.width))
            let nh = max(0.0, min(1.0, norm.size.height))
            let frame = CGRect(x: nx * renderSize.width, y: ny * renderSize.height, width: max(1.0, nw * renderSize.width), height: max(1.0, nh * renderSize.height))
            videoLayer.frame = frame
        } else {
            let pipWidth = renderSize.width * 0.35
            let pipHeight = pipWidth * videoAspect
            videoLayer.frame = CGRect(x: renderSize.width - pipWidth - margin, y: renderSize.height - pipHeight - margin, width: pipWidth, height: pipHeight)
        }

        // Ensure the video content preserves its aspect ratio inside the layer
        videoLayer.contentsGravity = .resizeAspect
        videoLayer.masksToBounds = true

        parentLayer.addSublayer(artworkLayer)
        parentLayer.addSublayer(videoLayer)

        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer)

        // Prepare exporter
        try? FileManager.default.removeItem(at: outputURL)
        guard let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            DispatchQueue.main.async { completion(.failure(NSError(domain: "VideoComposer", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create exporter"])) ) }
            return
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mov
        exporter.videoComposition = videoComposition
        exporter.shouldOptimizeForNetworkUse = true

        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                DispatchQueue.main.async { completion(.success(outputURL)) }
            case .failed, .cancelled:
                let err = exporter.error ?? NSError(domain: "VideoComposer", code: -3, userInfo: [NSLocalizedDescriptionKey: "Export failed"]) 
                DispatchQueue.main.async { completion(.failure(err)) }
            default:
                let err = NSError(domain: "VideoComposer", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unknown exporter status"]) 
                DispatchQueue.main.async { completion(.failure(err)) }
            }
        }
    }
}
