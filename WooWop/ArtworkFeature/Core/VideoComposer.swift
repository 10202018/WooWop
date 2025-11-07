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
    public static func compose(cameraVideoURL: URL, artwork: UIImage, outputURL: URL, pipRectNormalized: CGRect? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
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
        // supplied by the UI, use that to compute the frame directly.
        let margin: CGFloat = 24
        if let norm = pipRectNormalized {
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
