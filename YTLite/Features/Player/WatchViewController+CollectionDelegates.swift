import UIKit

// MARK: - UICollectionViewDataSource

extension WatchViewController: UICollectionViewDataSource {
    private func configureChannelNavigation(
        for cell: VideoCell,
        video: Video
    ) {
        cell.onChannelTap = { [weak self] in
            guard let self,
                  let channelId = video.channelId
            else {
                return
            }
            navigationController?.pushViewController(
                channelViewControllerFactory(
                    channelId,
                    video.channelName
                ),
                animated: true
            )
        }
    }

    func numberOfSections(
        in collectionView: UICollectionView
    )
        -> Int {
        isPlaylistMode ? 2 : 1
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    )
        -> Int {
        if isPlaylistMode {
            return section == 0
                ? max(0, queue.videos.count - 1)
                : visibleRelatedVideos.count
        }
        return visibleRelatedVideos.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    )
        -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: VideoCell.reuseId,
            for: indexPath
        ) as? VideoCell else {
            return UICollectionViewCell()
        }
        let video: Video? = if isPlaylistMode {
            indexPath.section == 0
                ? queue.videos[safe: indexPath.item + 1]
                : visibleRelatedVideos[safe: indexPath.item]
        } else {
            visibleRelatedVideos[safe: indexPath.item]
        }
        guard let video else {
            return cell
        }
        let isLandscape =
            view.bounds.width > view.bounds.height
        cell.forceGridLayout = !isLandscape
        cell.configure(with: video)
        configureChannelNavigation(for: cell, video: video)
        cell.onLongPress = { [weak self] in
            self?.presentQueueMenu(for: video)
        }
        cell.onTap = { [weak self] in
            self?.handleRelatedTap(video)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    )
        -> UICollectionReusableView {
        guard isPlaylistMode,
              kind == UICollectionView
              .elementKindSectionHeader
        else {
            return UICollectionReusableView()
        }
        let header = collectionView
            .dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier:
                PlaylistSectionHeaderView.reuseIdentifier,
                for: indexPath
            ) as? PlaylistSectionHeaderView
            ?? PlaylistSectionHeaderView()
        let title: String = if indexPath.section == 0 {
            queue.isUserQueue
                ? "player.queue.sectionTitle".localized
                : queue.playlistTitle ?? "player.related.mix".localized
        } else {
            "player.related.title".localized
        }
        header.configure(
            title: title,
            color: ThemeManager.shared.primaryText
        )
        return header
    }
}

// MARK: - UICollectionViewDelegate

extension WatchViewController: UICollectionViewDelegate {
    /// Play is triggered by the cell's tap gesture (VideoCell.setupTap), not
    /// selection, so a long resting touch no longer counts as a tap. Still
    /// reject a tap landing within a short window after scrolling — touching
    /// to stop momentum, or a sub-threshold drag, is browsing, not a play
    /// request.
    func handleRelatedTap(_ video: Video) {
        let sinceScroll = ProcessInfo.processInfo.systemUptime
            - lastScrollActivity
        guard !isOuterScrollViewDragging,
              !scrollView.isDecelerating,
              !relatedCollectionView.isDecelerating,
              sinceScroll > 0.3
        else {
            return
        }
        navigateTo(video)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension WatchViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    )
        -> CGSize {
        guard isPlaylistMode else {
            return .zero
        }
        return CGSize(
            width: collectionView.bounds.width,
            height: 32
        )
    }
}

// MARK: - UIScrollViewDelegate

extension WatchViewController: UIScrollViewDelegate {
    func scrollViewWillBeginDragging(
        _ scrollView: UIScrollView
    ) {
        guard scrollView === self.scrollView else {
            return
        }
        isOuterScrollViewDragging = true
    }

    func scrollViewDidEndDragging(
        _ scrollView: UIScrollView,
        willDecelerate decelerate: Bool
    ) {
        guard scrollView === self.scrollView else {
            return
        }
        if !decelerate {
            isOuterScrollViewDragging = false
        }
    }

    func scrollViewDidEndDecelerating(
        _ scrollView: UIScrollView
    ) {
        guard scrollView === self.scrollView else {
            return
        }
        isOuterScrollViewDragging = false
    }

    func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {
        if scrollView === self.scrollView
            || scrollView === relatedCollectionView {
            lastScrollActivity = ProcessInfo.processInfo.systemUptime
        }
        guard scrollView === self.scrollView else {
            return
        }
        let threshold: CGFloat = 400
        let offset = scrollView.contentOffset.y
            + scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        guard contentHeight > 0,
              offset >= contentHeight - threshold
        else {
            return
        }
        expandRelatedIfNeeded()
    }
}

// MARK: - PlaybackContext

extension WatchViewController: PlaybackContext {
    func updateStatusLabel(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            playerStatusLabel.text = text
            playerStatusLabel.isHidden = false
            playerSpinner.startAnimating()
        }
    }

    func setCaptionTracks(_ tracks: [SubtitleTrack]) {
        captionTracks = tracks
        videoPlayerView?.setCaptionTracks(
            tracks,
            activeLanguage: activeSubtitleLanguage
        )
        videoPlayerView?.onCCTapped = { [weak self] in
            self?.showSubtitlePicker()
        }
    }
}

// MARK: - Safe Collection Subscript

private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
