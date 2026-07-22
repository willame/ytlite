import Foundation

final class PlaybackQueue {
    static let shared = PlaybackQueue()
    private(set) var videos: [Video] = []
    private(set) var playlistTitle: String?
    /// True when the queue was built by the user (Play next / Add to queue)
    /// rather than loaded from a playlist — drives the section header text.
    private(set) var isUserQueue = false

    var hasNext: Bool {
        videos.count > 1
    }

    var currentVideo: Video? {
        videos.first
    }

    /// The upcoming video without advancing — navigation syncs the queue
    /// itself via `seekTo` once the next page loads.
    var nextVideo: Video? {
        hasNext ? videos[1] : nil
    }

    private init() {}

    func setQueue(
        _ videos: [Video],
        title: String? = nil
    ) {
        self.videos = videos
        self.playlistTitle = title
        isUserQueue = false
    }

    func seekTo(videoId: String) {
        guard let idx = videos.firstIndex(
            where: { $0.id == videoId }
        ) else {
            return
        }
        if idx > 0 {
            videos.removeFirst(idx)
        }
    }

    /// Insert `video` right after the current one so it plays next. Seeds
    /// the queue with `currentVideo` when empty so the existing "play queue
    /// next" plumbing (playToEnd / remote next) picks it up. Never sets a
    /// title, so a user-built queue stays out of playlist mode.
    func playNext(_ video: Video, currentVideo: Video?) {
        isUserQueue = true
        videos.removeAll { $0.id == video.id }
        if videos.isEmpty {
            if let current = currentVideo, current.id != video.id {
                videos = [current, video]
            } else {
                videos = [video]
            }
            return
        }
        videos.insert(video, at: 1)
    }

    /// Append `video` to the end of the queue. Seeds with `currentVideo`
    /// when empty, same as `playNext`.
    func addToQueue(_ video: Video, currentVideo: Video?) {
        isUserQueue = true
        videos.removeAll { $0.id == video.id }
        if videos.isEmpty,
           let current = currentVideo,
           current.id != video.id {
            videos = [current]
        }
        videos.append(video)
    }

    func clear() {
        videos = []
        playlistTitle = nil
        isUserQueue = false
    }
}
