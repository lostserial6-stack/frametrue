import AVFoundation
import CoreGraphics

/// Post-capture finalization for FrameTrue.
///
/// FrameTrue only knows the winning orientation after recording stops, while an
/// AVAssetWriterInput transform must be set before writing starts. Therefore the
/// reference flow is:
///   1. record to a temporary movie using the normal capture pipeline;
///   2. finish FrameTrueTracker;
///   3. create an AVMutableComposition from the temporary asset;
///   4. set the composition video track's preferredTransform;
///   5. export with AVAssetExportPresetPassthrough.
///
/// This changes presentation metadata while allowing the media tracks to pass
/// through without intentionally re-encoding them.
enum FrameTrueAVFoundation {
    static func canonicalTransform(for orientation: FrameTrueOrientation) -> CGAffineTransform {
        // Reference transforms only. A production adapter should map the chosen
        // semantic orientation relative to the actual camera sensor/capture
        // pipeline. RotationCoordinator is the preferred source for that mapping.
        switch orientation {
        case .portrait:
            return CGAffineTransform(rotationAngle: .pi / 2)
        case .portraitUpsideDown:
            return CGAffineTransform(rotationAngle: -.pi / 2)
        case .landscapeRight:
            return CGAffineTransform(rotationAngle: .pi)
        case .landscapeLeft, .unknown:
            return .identity
        }
    }

    static func finalize(
        inputURL: URL,
        outputURL: URL,
        result: FrameTrueResult,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        let asset = AVURLAsset(url: inputURL)
        let composition = AVMutableComposition()

        guard let sourceVideo = asset.tracks(withMediaType: .video).first,
              let destinationVideo = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
              ) else {
            completion(.failure(FrameTrueError.missingVideoTrack))
            return
        }

        do {
            try destinationVideo.insertTimeRange(
                CMTimeRange(start: .zero, duration: asset.duration),
                of: sourceVideo,
                at: .zero
            )
            destinationVideo.preferredTransform = canonicalTransform(for: result.orientation)

            for sourceAudio in asset.tracks(withMediaType: .audio) {
                guard let destinationAudio = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else { continue }
                try destinationAudio.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: sourceAudio,
                    at: .zero
                )
            }
        } catch {
            completion(.failure(error))
            return
        }

        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetPassthrough
        ) else {
            completion(.failure(FrameTrueError.cannotCreateExporter))
            return
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mov
        exporter.exportAsynchronously {
            switch exporter.status {
            case .completed:
                completion(.success(outputURL))
            case .failed, .cancelled:
                completion(.failure(exporter.error ?? FrameTrueError.exportFailed))
            default:
                break
            }
        }
    }
}

enum FrameTrueError: Error {
    case missingVideoTrack
    case cannotCreateExporter
    case exportFailed
}
