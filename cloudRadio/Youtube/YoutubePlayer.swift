
import youtube_ios_player_helper_swift

enum PlayDirection {
    case PREV
    case NEXT
}


class YoutubePlayer {
    private let ytView = YTPlayerView()
    
    private var IsNeedPlay = false
    var curIndex = 0
    var listCount = 0
    var IsShuffle: Bool = false
    var state: YTPlayerState = .unknown
    var curAlbumUrl: String? = nil
    var ranList = [YoutubeVideLists]()
    static var durationTime = 0
    static var playTime = 0
    static var IsYoutubePlaying: YTPlayerState = .unknown

    let downloader = YoutubePlaylistDownloader()
    var playlistName: String? = nil
    var playlistId: String = ""{
        didSet {
            if !playlistId.isEmpty {
                self.downloader.playlistId = self.playlistId
            }
        }
    }

    func initialize() {
        Log.print("YoutubePlayer init()")
        self.downloader.delegate = self
        
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.isHidden = true
        ytView.delegate = self
        ytView.frame = view.bounds
        ytView.isUserInteractionEnabled = false
    }
    
    func updateVideoInfo() {
        Log.print("updateVideoInfo()")
        YoutubePlayer.IsYoutubePlaying = .buffering
        HomeViewController.programName = (self.downloader.pList.list?[curIndex].titles)! + "      "
        HomeViewController.channelName = self.playlistName!
        self.curAlbumUrl = self.downloader.pList.list?[curIndex].thumbnail
        
        NotificationCenter.default.post(name: .updateAlbumArtMainYT, object: nil)
    }
    
    func stopVideo() {
        Log.print("stopVideo() ~")
        self.curAlbumUrl = nil
        ytView.stopVideo()
    }
    func pauseVideo() {
        Log.print("pauseVideo() ~")
        ytView.pauseVideo()
    }
    func resumeVideo() {
        Log.print("resumeVideo() ~")
        ytView.playVideo()
    }
    
    func requestNextVideo() {
        if self.state == .playing || self.state == .ended {
            self.stopVideo()
        }
        
        let videoId: String
        
        Log.print("curIndx: \(curIndex)   size: \(self.downloader.pList.list?.count)")
        
        if IsShuffle {
            videoId = self.ranList[curIndex].videoIds
        } else {
            videoId = self.downloader.pList.list![curIndex].videoIds
        }
        
        let playerVars:[String: Any] = [
            "controls" : "0",
            "showinfo" : "0",
            "autoplay": "1",
            "rel": "0",
            "modestbranding": "0",
            "iv_load_policy" : "3",
            "fs": "0",
            "playsinline" : "1"
        ]
        if !ytView.load(videoId: videoId, playerVars: playerVars) {
            Log.print("loading failed")
        } else {
            updateVideoInfo()
            IsNeedPlay = true
            Log.print("loading success")
        }
    }
    
    func setCurrentVideoIndex(direction: PlayDirection) {
        switch direction {
        case .PREV:
            if self.curIndex == 0 {
                curIndex = self.listCount - 1
            } else {
                curIndex -= 1
            }
            break
        case .NEXT:
            if self.listCount == (curIndex+1) {
                curIndex = 0
            } else {
                curIndex += 1
            }
            break
        }
    }
    
    static func getDurationTime() -> Double {
        return Double(durationTime)
    }
    
    static func getPlayTime() -> Double {
        return Double(playTime)
    }
}

extension YoutubePlayer: YTPlayerViewDelegate{
    func playerViewDidBecomeReady(_ playerView: YTPlayerView) {
        Log.print("playerViewDidBecomeReady")
        
        if IsNeedPlay {
            Log.print("PlayVideo() ~")
            ytView.playVideo()
            IsNeedPlay = false
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo quality: YTPlaybackQuality) {
        Log.print("Quality :: \(quality)")
    }
    
    //    func playerViewPreferredInitialLoadingView(_ playerView: YTPlayerView) -> UIView? {
    //        let loader = UIView(frame: CGRect(x: 10, y: 10, width: 200, height: 200))
    //        loader.backgroundColor = UIColor.brown
    //        return loader
    //    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        if self.state != state {
            Log.print("playerView state: \(state)")
            self.state = state
        }
        YoutubePlayer.IsYoutubePlaying = self.state

        switch self.state {
        case .playing, .buffering, .queued, .paused:
            Log.print("on going")
            break
        case .ended:
            Log.print("go Next Video")
            setCurrentVideoIndex(direction: PlayDirection.NEXT)
            requestNextVideo()
            break
        case .unknown, .unstarted:
            Log.print("ERROR?")
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
//        Log.print("playTime: \(Int(playTime)) / \(ytView.duration)")
        YoutubePlayer.durationTime = Int(ytView.duration)
        YoutubePlayer.playTime = Int(playTime)
    }
}

extension YoutubePlayer: YoutubePlaylistDownloaderDelegate {
    func downloadState(state: DownloadingState) {
        Log.print("downloadState: \(state)")
        if ( state == DownloadingState.FINISHED ) {
            self.listCount = self.downloader.pList.list?.count ?? 0
            let videoId = self.downloader.pList.list?[curIndex].videoIds ?? "m3DZsBw5bnE"
            let playerVars:[String: Any] = [
                "controls" : "0",
                "showinfo" : "0",
                "autoplay": "1",
                "rel": "0",
                "modestbranding": "0",
                "iv_load_policy" : "3",
                "fs": "0",
                "playsinline" : "1"
            ]
            curIndex = 0
            if !ytView.load(videoId: videoId, playerVars: playerVars) {
                Log.print("loading failed")
            } else {
                updateVideoInfo()
                IsNeedPlay = true
                Log.print("loading success")
            }
        }
    }
}
