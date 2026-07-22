import UIKit

// MARK: - Play queue (Play next / Add to queue)

extension WatchViewController {
    /// Long-pressing a related video lines it up in the playback queue.
    /// The queue is already honored by playToEnd and remote next, so this
    /// only mutates it — no player changes.
    func presentQueueMenu(for video: Video) {
        let current = watchPage?.video ?? initialVideo
        let items: [PlayerMenuItem] = [
            PlayerMenuItem(
                title: "player.queue.playNext".localized
            ) { [weak self] in
                self?.queue.playNext(video, currentVideo: current)
                self?.showQueueToast(
                    "player.queue.added.playNext".localized
                )
            },
            PlayerMenuItem(
                title: "player.queue.addToQueue".localized
            ) { [weak self] in
                self?.queue.addToQueue(video, currentVideo: current)
                self?.showQueueToast(
                    "player.queue.added.queue".localized
                )
            }
        ]
        presentPlayerMenu(title: video.title, items: items)
    }

    /// Minimal self-dismissing toast, anchored to the window so it shows
    /// over the player in fullscreen too.
    private func showQueueToast(_ message: String) {
        guard let window = view.window else {
            return
        }
        let container = makeToastContainer()
        let label = makeToastLabel(message)
        container.addSubview(label)
        window.addSubview(container)
        pinToastLabel(label, in: container)
        pinToast(container, in: window)
        animateToast(container)
    }

    private func makeToastContainer() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        container.alpha = 0
        return container
    }

    private func makeToastLabel(_ message: String) -> UILabel {
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

    private func pinToastLabel(_ label: UILabel, in container: UIView) {
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(
                equalTo: container.topAnchor, constant: 10
            ),
            label.bottomAnchor.constraint(
                equalTo: container.bottomAnchor, constant: -10
            ),
            label.leadingAnchor.constraint(
                equalTo: container.leadingAnchor, constant: 16
            ),
            label.trailingAnchor.constraint(
                equalTo: container.trailingAnchor, constant: -16
            )
        ])
    }

    private func pinToast(_ container: UIView, in window: UIView) {
        NSLayoutConstraint.activate([
            container.centerXAnchor.constraint(
                equalTo: window.centerXAnchor
            ),
            container.bottomAnchor.constraint(
                equalTo: window.safeAreaLayoutGuide.bottomAnchor,
                constant: -80
            ),
            container.leadingAnchor.constraint(
                greaterThanOrEqualTo: window.leadingAnchor, constant: 24
            ),
            container.trailingAnchor.constraint(
                lessThanOrEqualTo: window.trailingAnchor, constant: -24
            )
        ])
    }

    private func animateToast(_ container: UIView) {
        UIView.animate(
            withDuration: 0.25,
            animations: { container.alpha = 1 },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.25,
                    delay: 1.2,
                    options: [],
                    animations: { container.alpha = 0 },
                    completion: { _ in container.removeFromSuperview() }
                )
            }
        )
    }
}
