import Foundation

/// Strategy for client-specific pipeline behavior.
/// Encapsulates auth token fetching and fallback decisions.
protocol PlaybackPipelineStrategy {
    /// Fetch auth token needed for direct playback.
    /// Returns nil if the client doesn't need one.
    func fetchAuthToken(
        videoId: String,
        completion: @escaping (String?) -> Void
    )

    /// Whether to try onesie fallback when no direct
    /// streams are available.
    func shouldTryOnesieFallback(
        info: DirectPlaybackInfo
    )
        -> Bool
}

/// ANDROID_VR: no PoToken needed, no onesie fallback.
struct AndroidVRPipelineStrategy: PlaybackPipelineStrategy {
    func fetchAuthToken(
        videoId: String,
        completion: @escaping (String?) -> Void
    ) {
        AppLog.player(
            "PoToken: skipping for ANDROID_VR"
        )
        completion(nil)
    }

    func shouldTryOnesieFallback(
        info: DirectPlaybackInfo
    ) -> Bool {
        false
    }
}

/// WebClient: needs PoToken, can use onesie fallback.
struct WebClientPipelineStrategy: PlaybackPipelineStrategy {
    func fetchAuthToken(
        videoId: String,
        completion: @escaping (String?) -> Void
    ) {
        WebPoTokenService.shared.fetchSessionToken(
            identifier: videoId
        ) { result in
            switch result {
            case let .success(token):
                completion(token)
            case let .failure(error):
                AppLog.player(
                    "PoToken failed: \(error)"
                )
                completion(nil)
            }
        }
    }

    func shouldTryOnesieFallback(
        info: DirectPlaybackInfo
    ) -> Bool {
        info.serverAbrStreamingURL != nil
    }
}
