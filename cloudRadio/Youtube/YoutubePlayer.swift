
import youtube_ios_player_helper_swift
import MediaPlayer

enum PlayDirection {
    case PREV
    case NEXT
    case NONE
}


class YoutubePlayer {
    let ytView = YTPlayerView()
    var audioSession: AVAudioSession? = nil
    
    private var IsNeedPlay = false
    var state: YTPlayerState = .unknown
    var curAlbumUrl: String? = nil
    static var durationTime = 0
    static var playTime = 0
    static var PlayingState: YTPlayerState = .unknown

    let downloader = YoutubePlaylistDownloader()
    var playlistName: String? = nil
    var playlistId: String = ""{
        didSet {
            if !self.playlistId.isEmpty {
                YoutubePlayer.playTime = 0
                self.downloader.playlistId = self.playlistId
            }
        }
    }
    
    var watchTimer: Timer?
    var waitTimeToPlay: Int = 0
    var playDirection: PlayDirection = .NONE
    
    var IsShuffle = CloudRadioShareValues.IsShuffle
    var IsRepeat = CloudRadioShareValues.IsRepeat
    
    func initialize() {
        Log.print("YoutubePlayer init() IsShuffle: \(CloudRadioShareValues.IsShuffle) IsRepeat: \(CloudRadioShareValues.IsRepeat)")
        self.downloader.delegate = self
        
        ytView.delegate = self
        let view = UIView()
        view.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
//        view.isHidden = true
        ytView.frame = view.bounds
        ytView.isUserInteractionEnabled = false
    }
    
    private func getVideoId(addr: URL?) -> String {
        guard let addr = addr?.absoluteString else { return "N/A" }
        if ( addr.contains("https://www.youtube.com/watch?list=")
             && addr.contains(playlistId)
             && addr.contains("&v=") ) {
            let id = addr[addr.endIndex(of: "&v=")!..<addr.endIndex]
            return String(id)
        }
        return "N/A"
    }
    
    private func setProgramInfo(videoId: String) {
        guard let list = self.downloader.pList.list else {
            Log.print("ERROR: downloader list is nil")
            HomeViewController.setDefaultValues()
            return
        }
        
        for i in 0..<list.count {
            if videoId == list[i].videoIds {
                HomeViewController.programName = list[i].titles + "      "
                self.curAlbumUrl = list[i].thumbnail
            }
        }
        
        if HomeViewController.programName == "OnAir Ready" {
            Log.print("ERROR: Can't find videoID for \(videoId)")
        }
    }
    
    func updateVideoInfo() {
        Log.print("updateVideoInfo() IsShuffle: \(CloudRadioShareValues.IsShuffle) IsRepeat: \(CloudRadioShareValues.IsRepeat)")

        let videoId = getVideoId(addr: self.ytView.videoUrl)
        if videoId == "N/A" {
            Log.print("Can't get videoId")
            HomeViewController.setDefaultValues()
        } else {
            HomeViewController.setDefaultValues()
            HomeViewController.channelName = self.playlistName!
            setProgramInfo(videoId: videoId)
        }
        
        NotificationCenter.default.post(name: .updateAlbumArtMainYT, object: nil)
    }
    
    func stopVideo() {
        Log.print("stopVideo() ~")
        self.waitTimeToPlay = 0
        self.curAlbumUrl = nil
        self.ytView.stopVideo()
    }
    
    func pauseVideo() {
        if self.state == .playing {
            Log.print("pauseVideo() ~")
            self.ytView.pauseVideo()
        } else {
            Log.print("Ignore: pauseVide(). It's not playing state")
        }
    }
    
    func checkShuffleRepeat() {
        if IsShuffle != CloudRadioShareValues.IsShuffle {
            IsShuffle = CloudRadioShareValues.IsShuffle
            self.ytView.set(shuffle: IsShuffle)
        }
        
        if IsRepeat != CloudRadioShareValues.IsRepeat {
            IsRepeat = CloudRadioShareValues.IsRepeat
            self.ytView.set(loop: IsRepeat)
        }
    }
    
    func resumeVideo() {
        Log.print("resumeVideo() ~")
        self.checkShuffleRepeat()
        self.ytView.playVideo()
    }
    
    func requestNextVideo() {
        self.pauseVideo()
                

        Log.print("go Next Video() ~")
        playDirection = .NEXT
        //self.ytView.nextVideo()
    }
    
    func requestPrevVideo() {
        self.pauseVideo()
                        
        Log.print("go Previous Video() ~")
        playDirection = .PREV
        //self.ytView.previousVideo()
    }
    
    func loadingVideo(playlistId: String) {
        Log.print("loadingVideo() playlistId: \(playlistId)")
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
        if !self.ytView.load(playlistId: playlistId, playerVars: playerVars) {
            Log.print("loading failed")
        } else {
            IsNeedPlay = true
            Log.print("loading success")
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
        IsShuffle = CloudRadioShareValues.IsShuffle
        IsRepeat = CloudRadioShareValues.IsRepeat
        
        Log.print("playerViewDidBecomeReady NeedPlay: \(IsNeedPlay) Shuffle: \(IsShuffle) Repeat: \(IsRepeat)")
        
        // Case of initial playing
        if IsNeedPlay {
            Log.print("Initial PlayVideo()")

            self.ytView.set(shuffle: IsShuffle)
            self.ytView.set(loop: IsRepeat)
            
            // shuffle 하는 순간 playlist array 의 indexing 이 바뀜
            // 0 번을 주면 shuffle 이후의 array 의 0 번부터 재생
            self.ytView.playVideo(at: 0)
            
            IsNeedPlay = false
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didChangeTo quality: YTPlaybackQuality) {
        Log.print("Quality :: \(quality)")
    }

    func playerView(_ playerView: YTPlayerView, didChangeTo state: YTPlayerState) {
        if self.state != state {
            Log.print("playerView state: \(state)")
            if CloudRadioShareValues.IsUnlockedFeature {
                if CloudRadioShareValues.IsLockScreen && CloudRadioShareValues.LockedPlay == false {
                    Log.print("resumeVideo on LockScreen")
                    self.resumeVideo()
                    CloudRadioShareValues.LockedPlay = true
                    return
                }
            }
            self.state = state
        } else {
            Log.print("playerView same state: \(state)")
        }
        YoutubePlayer.PlayingState = self.state

        switch self.state {
            case .buffering:
                YoutubePlayer.playTime = 0
                updateVideoInfo()
            case .playing:
                playDirection = .NONE
                Log.print("on going")
                break
            case .queued, .paused:
                Log.print("PLAYING TO \(playDirection)")
                if playDirection == .NEXT {
                    self.checkShuffleRepeat()
                    self.ytView.nextVideo()
                } else if playDirection == .PREV {
                    self.checkShuffleRepeat()
                    self.ytView.previousVideo()
                }
            case .ended:
                Log.print("go Next Video")
                // repeat=false, curIndex=99, listCount=100
                if !CloudRadioShareValues.IsRepeat {
                    Log.print("Playing Ends (Repeat false)")
                } else {
                    self.checkShuffleRepeat()
                    requestNextVideo()
                }
                break
            case .unstarted:
                Log.print("VIDEO COULD NOT PLAYED")
                if playDirection == .NEXT {
                    self.checkShuffleRepeat()
                    self.ytView.nextVideo()
                } else if playDirection == .PREV {
                    self.checkShuffleRepeat()
                    self.ytView.previousVideo()
                } else {
                    // default 는 next video
                    self.checkShuffleRepeat()
                    self.ytView.nextVideo()
                }
            case .unknown:
                Log.print("ERROR?")
        }
    }
    
    func playerView(_ playerView: YTPlayerView, didPlayTime playTime: Float) {
//        Log.print("playTime: \(Int(playTime)) / \(ytView.duration)")
        YoutubePlayer.durationTime = Int(self.ytView.duration)
        YoutubePlayer.playTime = Int(playTime)
    }
}

extension YoutubePlayer: YoutubePlaylistDownloaderDelegate {
    func downloadState(state: DownloadingState) {
        Log.print("downloadState: \(state)")
        if ( state == DownloadingState.FINISHED ) {
            loadingVideo(playlistId: self.downloader.playlistId)
        }
    }
}
