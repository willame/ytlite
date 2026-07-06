import AVKit
import UIKit

// MARK: - Picture in Picture

extension VideoPlayerView {
    /// Whether PiP is possible at all: device support + the user setting.
    var isPiPAvailable: Bool {
        let supported = AVPictureInPictureController
            .isPictureInPictureSupported()
        let enabled = UserDefaults.standard.object(
            forKey: UserDefaultsKeys.Player.pipEnabled
        ) as? Bool ?? true
        return supported && enabled
    }

    func setupPiP() {
        setControlAvailability(
            pipButton,
            available: isPiPAvailable
        )
        guard isPiPAvailable else {
            // Also drops a controller created before the user
            // disabled the setting — it would otherwise keep
            // serving the (reused) player layer.
            pipController = nil
            return
        }
        guard pipController == nil else {
            return
        }
        pipController = AVPictureInPictureController(
            playerLayer: playerLayer
        )
        pipController?.delegate = self
    }

    /// Auto-PiP on backgrounding is wanted only in fullscreen (with the
    /// setting on) — that case keeps its layer and controller. Everywhere
    /// else BOTH go away while inactive: a bare layer still gets paused by
    /// iOS (killing background audio), and a live controller can still be
    /// picked up for auto-PiP even mid-detach. Recreated on activation.
    @objc
    func appWillResignActive() {
        guard pipController?.isPictureInPictureActive != true else {
            return
        }
        if isFullscreen, pipController != nil {
            return
        }
        playerLayer.player = nil
        pipController = nil
    }

    @objc
    func appDidBecomeActive() {
        guard let player else {
            return
        }
        if playerLayer.player == nil {
            playerLayer.player = player
        }
        // Re-evaluate the PiP setting (it may have changed in Settings).
        setupPiP()
    }

    @objc
    func pipTapped() {
        guard let pip = pipController else {
            return
        }
        if pip.isPictureInPictureActive {
            pip.stopPictureInPicture()
        } else {
            pip.startPictureInPicture()
        }
    }
}

// MARK: - PiP Delegate

extension VideoPlayerView: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(
        _ controller: AVPictureInPictureController
    ) {
        pipButton.setImage(
            PlayerIcons.pipExit(),
            for: .normal
        )
    }

    func pictureInPictureControllerDidStopPictureInPicture(
        _ controller: AVPictureInPictureController
    ) {
        pipButton.setImage(
            PlayerIcons.pip(),
            for: .normal
        )
    }

    func pictureInPictureController(
        _ controller: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
            completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(true)
    }
}
