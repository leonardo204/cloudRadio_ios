
import YoutubeKit
import MediaPlayer

enum PlayDirection {
    case PREV
    case NEXT
}


class YoutubePlayer {
    var player: YTSwiftyPlayer!
    var audioSession: AVAudioSession? = nil

    var curIndex = 0
    var listCount = 0
    var state: YTSwiftyPlayerState = .unstarted
    var curAlbumUrl: String? = nil
    var ranList = [YoutubeVideLists]()
    static var durationTime = 0
    static var playTime = 0
    static var PlayingState: YTSwiftyPlayerState = .unstarted

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
        
//        let view = UIView()
//        view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
//        view.isHidden = true
//        ytView.delegate = self
//        ytView.frame = view.bounds
//        ytView.isUserInteractionEnabled = false
    }
    
    func updateVideoInfo() {
        Log.print("updateVideoInfo() IsShuffle: \(CloudRadioShareValues.IsShuffle) IsRepeat: \(CloudRadioShareValues.IsRepeat)")
        YoutubePlayer.PlayingState = .buffering
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
        player.stopVideo()
    }
    func pauseVideo() {
        Log.print("pauseVideo() ~")
        player.pauseVideo()
    }
    func resumeVideo() {
        Log.print("resumeVideo() ~")
        player.playVideo()
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
        
        player.loadVideo(videoID: videoId)
        updateVideoInfo()
    }
    
    private func loadInitVideo() {
        Log.print("Load init video")

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
        
        player = YTSwiftyPlayer(
            frame: CGRect(x: 6, y: 4, width: CloudRadioShareValues.videoViewBounds!.width, height: CloudRadioShareValues.videoViewBounds!.height),
            playerVars: [
                .videoID(videoId),
                .showRelatedVideo(false),
                .showInfo(false),
                .enableJavaScriptAPI(false),
                .playsInline(true),  //  true: frame 에서 재생, false: 전체화면으로 재생
                .showControls(VideoControlAppearance.hidden),
                .showLoadPolicy(true)
            ])

        player.autoplay = true
        player.isUserInteractionEnabled = false
        player.delegate = self

        player.loadPlayer()
        updateVideoInfo()
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

extension YoutubePlayer: YTSwiftyPlayerDelegate{
    func playerReady(_ player: YTSwiftyPlayer) {
        Log.print(#function)
    }
    
    func player(_ player: YTSwiftyPlayer, didUpdateCurrentTime currentTime: Double) {
        //Log.print("\(#function): \(currentTime) / \(player.duration)")
        YoutubePlayer.durationTime = Int(player.duration!)
        YoutubePlayer.playTime = Int(currentTime)
    }
    
    func player(_ player: YTSwiftyPlayer, didChangeState state: YTSwiftyPlayerState) {
        Log.print("\(#function): \(state)")
        if self.state != state {
            self.state = state
            YoutubePlayer.PlayingState = self.state

            Log.print("playerView state: \(state)")
            if CloudRadioShareValues.IsLockScreen && CloudRadioShareValues.LockedPlay == false {
                Log.print("resumeVideo on LockScreen")
                self.resumeVideo()
                CloudRadioShareValues.LockedPlay = true
                return
            }
        }
        
        switch self.state {
        case .playing, .buffering, .cued, .paused, .unstarted:
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
        }
    }
    
    func player(_ player: YTSwiftyPlayer, didChangePlaybackRate playbackRate: Double) {
        Log.print("\(#function): \(playbackRate)")
    }
    
    func player(_ player: YTSwiftyPlayer, didReceiveError error: YTSwiftyPlayerError) {
        Log.print("\(#function): \(error)")
    }
    
    func player(_ player: YTSwiftyPlayer, didChangeQuality quality: YTSwiftyVideoQuality) {
        Log.print("\(#function): \(quality)")
    }
    
    func apiDidChange(_ player: YTSwiftyPlayer) {
        Log.print("\(#function)")
    }
    
    func youtubeIframeAPIReady(_ player: YTSwiftyPlayer) {
        Log.print(#function)
    }
    
    func youtubeIframeAPIFailedToLoad(_ player: YTSwiftyPlayer) {
        Log.print(#function)
    }
}

extension YoutubePlayer: YoutubePlaylistDownloaderDelegate {
    func downloadState(state: DownloadingState) {
        Log.print("downloadState: \(state)")
        if ( state == DownloadingState.FINISHED ) {
            loadInitVideo()
        }
    }
}
