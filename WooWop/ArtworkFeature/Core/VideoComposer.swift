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
    public static func compose(cameraVideoURL: URL, artwork: UIImage, outputURL: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        let asset = AVAsset(url: cameraVideoURL)

        // Ensure the recorded asset has a video track
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            DispatchQueue.main.async { completion(.failure(NSError(domain: "VideoComposer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track found"]))) }
            return
        }

        // Compute render size from video track's naturalSize and preferredTransform
        let transformedSize = videoTrack.naturalSize.applying(videoTrack.preferredTransform)
        let renderSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))

        let composition = AVMutableComposition()
        do {
            if let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) {
                try compVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: videoTrack, at: .zero)
                compVideoTrack.preferredTransform = videoTrack.preferredTransform
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
            // Keep original transform so orientation is preserved
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
        // PIP width is 35% of render width
        let pipWidth = renderSize.width * 0.35
        let videoAspect = abs(videoTrack.naturalSize.height / videoTrack.naturalSize.width)
        let pipHeight = pipWidth * videoAspect
        let margin: CGFloat = 24
        videoLayer.frame = CGRect(x: renderSize.width - pipWidth - margin, y: renderSize.height - pipHeight - margin, width: pipWidth, height: pipHeight)
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
