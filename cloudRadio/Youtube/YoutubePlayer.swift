
import youtube_ios_player_helper_swift
import MediaPlayer

enum PlayDirection {
    case PREV
    case NEXT
}


class YoutubePlayer {
    private let ytView = YTPlayerView()
    var audioSession: AVAudioSession? = nil

    private var IsNeedPlay = false
    var curIndex = 0
    var listCount = 0
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
        Log.print("YoutubePlayer init() IsShuffle: \(CloudRadioShareValues.IsShuffle) IsRepeat: \(CloudRadioShareValues.IsRepeat)")
        self.downloader.delegate = self
        
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        view.isHidden = true
        ytView.delegate = self
        ytView.frame = view.bounds
        ytView.isUserInteractionEnabled = false
    }
    
    func updateVideoInfo() {
        Log.print("updateVideoInfo() IsShuffle: \(CloudRadioShareValues.IsShuffle) IsRepeat: \(CloudRadioShareValues.IsRepeat)")
        YoutubePlayer.IsYoutubePlaying = .buffering
        HomeViewController.channelName = self.playlistName!

        if CloudRadioShareValues.IsShuffle {
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
        
        if CloudRadioShareValues.IsShuffle {
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
    // 약 5초 정도 기다린 후 재생되지 않으면, 다음 비디오로 넘긴다.
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
            if !CloudRadioShareValues.IsRepeat && curIndex == (self.listCount-1) {
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

    func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession!.setCategory(.playback, mode: .default, options: [])
            try audioSession!.setActive(true)

            // 1. 전화가 오는 등의 인터럽트 상황에 발생하는 Notification 등록
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(handleInterruption),
                                                   name: AVAudioSession.interruptionNotification,
                                                   object: audioSession)
        } catch {
            Log.print("Error setting the AVAudioSession: \(error.localizedDescription)")
        }
    }

    // 2. 처리
    @objc func handleInterruption(notification: Notification) {
        Log.print("YT) handleInterruption called")

        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                Log.print("YT) ERROR to handle interrupt")
                return
        }

        // Switch over the interruption type.
        switch type {

        case .began:
            // An interruption began. Update the UI as necessary.
            Log.print("YT) interrupt start")
            if self.state == .playing {
                self.pauseVideo()
            }
        case .ended:
           // An interruption ended. Resume playback, if appropriate.
            Log.print("YT) interrupt end")

            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // An interruption ended. Resume playback.
                if self.state == .paused {
                    Log.print("YT) playback resume")
                    self.resumeVideo()
                }

            } else {
                // An interruption ended. Don't resume playback.
                Log.print("YT) playback didn't resume")
            }
        default:
            Log.print("YT) default?")
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
            if CloudRadioShareValues.IsLockScreen && CloudRadioShareValues.LockedPlay == false {
                Log.print("resumeVideo on LockScreen")
                self.resumeVideo()
                CloudRadioShareValues.LockedPlay = true
                return
            }
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
            if !CloudRadioShareValues.IsRepeat && curIndex == (self.listCount-1) {
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
            guard let list = self.downloader.pList.list else {
                Log.print("Failed to get youtube playlist")
                return
            }
            self.listCount = list.count
            self.ranList = list.shuffled()
            let videoId: String
            if CloudRadioShareValues.IsShuffle {
                videoId = self.ranList[curIndex].videoIds
            } else {
                videoId = list[curIndex].videoIds
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
