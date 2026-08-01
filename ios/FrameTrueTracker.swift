import Foundation
import UIKit

enum FrameTrueOrientation {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight
    case unknown
}

struct FrameTrueResult {
    let orientation: FrameTrueOrientation
    let portraitSeconds: TimeInterval
    let landscapeSeconds: TimeInterval
    let unknownSeconds: TimeInterval
    let confidence: Double
}

final class FrameTrueTracker {
    private var durations: [FrameTrueOrientation: TimeInterval] = [:]
    private var current: FrameTrueOrientation = .unknown
    private var lastTimestamp: TimeInterval?

    func reset() {
        durations.removeAll()
        current = .unknown
        lastTimestamp = nil
    }

    func start(_ orientation: FrameTrueOrientation,
               timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        reset()
        current = orientation
        lastTimestamp = timestamp
    }

    func update(_ orientation: FrameTrueOrientation,
                timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) {
        accrue(timestamp)
        current = orientation
    }

    func finish(timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime) -> FrameTrueResult {
        accrue(timestamp)
        lastTimestamp = nil
        return result()
    }

    private func accrue(_ timestamp: TimeInterval) {
        guard let last = lastTimestamp else {
            lastTimestamp = timestamp
            return
        }
        let dt = max(0, timestamp - last)
        durations[current, default: 0] += dt
        lastTimestamp = timestamp
    }

    func result() -> FrameTrueResult {
        let portrait = durations[.portrait, default: 0] + durations[.portraitUpsideDown, default: 0]
        let landscape = durations[.landscapeLeft, default: 0] + durations[.landscapeRight, default: 0]
        let unknown = durations[.unknown, default: 0]
        let classified = portrait + landscape

        guard classified > 0 else {
            return .init(orientation: .unknown,
                         portraitSeconds: portrait,
                         landscapeSeconds: landscape,
                         unknownSeconds: unknown,
                         confidence: 0)
        }

        let final: FrameTrueOrientation = landscape >= portrait ? .landscapeLeft : .portrait
        return .init(orientation: final,
                     portraitSeconds: portrait,
                     landscapeSeconds: landscape,
                     unknownSeconds: unknown,
                     confidence: max(portrait, landscape) / classified)
    }
}

extension FrameTrueOrientation {
    static func from(_ deviceOrientation: UIDeviceOrientation) -> FrameTrueOrientation {
        switch deviceOrientation {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return .unknown
        }
    }
}
