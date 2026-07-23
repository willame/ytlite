import UIKit

// MARK: - Playback Speed Controls

extension VideoPlayerView {
    @objc
    func speedTapped() {
        let isVisible = !speedOverlay.isHidden
        speedOverlay.isHidden = isVisible
        if !isVisible {
            pauseAutoHide()
        } else {
            speedLabel.text = formatSpeedLabel(playbackSpeed)
            updateSpeedSelection()
            scheduleAutoHide()
        }
    }

    @objc
    func speedPresetTapped(_ sender: UIButton) {
        guard speedPresets.indices.contains(sender.tag) else {
            return
        }
        playbackSpeed = speedPresets[sender.tag]
        speedLabel.text = formatSpeedLabel(playbackSpeed)
        updateSpeedSelection()
        scheduleAutoHide()
    }

    /// Highlight the chip matching the active speed; dim the rest.
    func updateSpeedSelection() {
        for button in speedButtons {
            guard speedPresets.indices.contains(button.tag) else {
                continue
            }
            let selected = abs(
                speedPresets[button.tag] - playbackSpeed
            ) < 0.01
            button.backgroundColor = selected
                ? UIColor.white.withAlphaComponent(0.9)
                : UIColor.white.withAlphaComponent(0.15)
            button.setTitleColor(
                selected ? .black : .white,
                for: .normal
            )
        }
    }

    /// Big label above the chips, e.g. "1.50x".
    func formatSpeedLabel(_ speed: Float) -> String {
        String(format: "%.2f", speed) + "x"
    }

    /// Compact chip / control-bar label, e.g. "1x", "1.25x".
    func formatSpeedChip(_ speed: Float) -> String {
        speed == 1.0
            ? "1x"
            : String(format: "%g", speed) + "x"
    }

    func updateSpeedButtonTitle() {
        let title = formatSpeedChip(playbackSpeed)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.white
        ]
        let attributed = NSAttributedString(
            string: title,
            attributes: attrs
        )
        speedButton.setAttributedTitle(
            attributed,
            for: .normal
        )
    }
}
