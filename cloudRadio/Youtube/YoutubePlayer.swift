
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
    var IsShuffle: Bool = CloudRadioShareValues.isShuffle
    var IsRepeat: Bool = CloudRadioShareValues.isRepeat
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
    
    var watchTimer: Timer?
    var waitTimeToPlay: Int = 0
    
    func initialize() {
        Log.print("YoutubePlayer init() IsShuffle: \(IsShuffle) IsRepeat: \(IsRepeat)")
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
        HomeViewController.channelName = self.playlistName!

        if IsShuffle {
            HomeViewController.programName = self.ranList[curIndex].titles + "      "
            self.curAlbumUrl = self.ranList[curIndex].thumbnail
        } else {
            HomeViewController.programName = (self.downloader.pList.list?[curIndex].titles)! + "      "
            self.curAlbumUrl = self.downloader.pList.list?[curIndex].thumbnail
        }
        
        NotificationCenter.default.post(name: .updateAlbumArtMainYT, object: nil)
    }
    
    func stopVideo() {
        Log.print("stopVideo() ~")
        // 자동재생이 되지 않으면 state 도 안올라옴
        self.state = .ended
        self.waitTimeToPlay = 0
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
        
        Log.print("curIndx: \(curIndex)   size: \(String(describing: self.downloader.pList.list?.count))")
        
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
    
    
    // 여러 가지 이유로 일부 비디오는 자동 재생이 되지 않는다.
    // 약 3초 정도 기다린 후 재생되지 않으면, 다음 비디오로 넘긴다.
    @objc func watchingPlayState(timer: Timer) {
        Log.print("watchingPlayState(\(self.waitTimeToPlay)): \(self.state)")
        self.waitTimeToPlay += 1
        
        if self.state == .playing {
            Log.print("Playing OK")
            self.waitTimeToPlay  = 0
            self.watchTimer?.invalidate()
        }
        
        if self.waitTimeToPlay > 5 {
            Log.print("go Next Video by FORCE")
            // repeat=false, curIndex=99, listCount=100
            if !IsRepeat && curIndex == (self.listCount-1) {
                Log.print("Playing Ends (Repeat false)")
            } else {
                // 자동재생이 되지 않으면 state 도 안올라옴
                self.state = .ended
                setCurrentVideoIndex(direction: PlayDirection.NEXT)
                requestNextVideo()
            }
            self.waitTimeToPlay  = 0
            self.watchTimer?.invalidate()
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
            self.watchTimer?.invalidate()
            self.watchTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.watchingPlayState), userInfo: nil, repeats: true)
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
            // repeat=false, curIndex=99, listCount=100
            if !IsRepeat && curIndex == (self.listCount-1) {
                Log.print("Playing Ends (Repeat false)")
            } else {
                setCurrentVideoIndex(direction: PlayDirection.NEXT)
                requestNextVideo()
            }
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
            for i in 0..<self.listCount {
                self.ranList.insert(self.downloader.pList.list![i], at: i)
            }
            self.ranList.shuffle()
            let videoId: String
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
