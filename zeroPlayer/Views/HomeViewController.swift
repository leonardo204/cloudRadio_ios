//
//  ViewController.swift
//  CustomSideMenuiOSExample
//
//  Created by John Codeos on 2/§/21.
//

import UIKit
import MarqueeLabel

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
    func downloaded(from url: URL, contentMode mode: ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else {
            Log.print("Fail url")
            return
        }
        downloaded(from: url, contentMode: mode)
    }
}

class HomeViewController: UIViewController {

    
    @IBOutlet var sideMenuBtn: UIBarButtonItem!
    
    // media controls
    @IBOutlet weak var previousImageview: UIImageView!
    @IBOutlet weak var playImageview: UIImageView!
    @IBOutlet weak var pauseImageview: UIImageView!
    @IBOutlet weak var skipImageview: UIImageView!
    
    
    
    @IBOutlet weak var starttimeLabel: UILabel!
    @IBOutlet weak var endtimeLabel: UILabel!
    
    @IBOutlet weak var albumImageView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var initialLabel: UILabel!
    var initialMessage: String = String("Welcome to zeroPlayer")
    @IBOutlet weak var programNameLabel: MarqueeLabel!
    @IBOutlet weak var channelNameLabel: UILabel!
    static var channelName: String = String("")
    static var programName: String = String("")
    static var albumArtPath: String = "http://zerolive7.iptime.org:9093/api/public/dl/CCxak7Jj/01_project/cloudradio/cosmos1.jpeg"
    
    static var homeViewInitialLoaded: Bool = true
    
    var progressTimer: Timer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setImageViewButton()
        
//        updateAlbumArt(path: HomeViewController.albumArtPath)
        updateProgressView()
//        updateLabel()
        
        self.view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

        // Menu Button Tint Color
        navigationController?.navigationBar.tintColor = .white

        sideMenuBtn.target = revealViewController()
        sideMenuBtn.action = #selector(revealViewController()?.revealSideMenu)
        
        Log.print("home viewDidLoad()")
    }
    
    @IBAction func onStopBtnClicked(_ sender: Any) {
        Log.print("onStopBtnClicked")
        NotificationCenter.default.addObserver(self, selector: #selector(isPlayingAnswer(_:)), name: .isPlayingAnswerHome, object: nil)
        NotificationCenter.default.post(name: .isPlayingQueryMain, object: nil)
    }

    
    func doStopButtonImpl(playState: RadioPlayStatus) {
        Log.print("playState: \(playState)")
        if ( playState != RadioPlayStatus.stopped ) {
            NotificationCenter.default.post(name: .stopRadioMain, object: nil)
            HomeViewController.setDefaultValues()
            updateLabel()
            updateAlbumArt(path: HomeViewController.albumArtPath)
        }
    }
    
    @objc func isPlayingAnswer(_ notification: NSNotification) {
        NotificationCenter.default.removeObserver(self, name: .isPlayingAnswerHome, object: nil)
        
        if let isPlaying = notification.object as? RadioPlayStatus {
            doStopButtonImpl(playState: isPlaying)
        }
    }
    
    func setImageViewButton() {
        self.previousImageview.isUserInteractionEnabled = true
        let previous: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onPreviousClicked(recognizer:)))
        previous.numberOfTapsRequired = 1
        self.previousImageview.addGestureRecognizer(previous)
        
        self.pauseImageview.isUserInteractionEnabled = true
        let pause: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onPauseClicked(recognizer:)))
        pause.numberOfTapsRequired = 1
        self.pauseImageview.addGestureRecognizer(pause)
        
        self.skipImageview.isUserInteractionEnabled = true
        let skip: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onSkipBtnClicked(recognizer:)))
        skip.numberOfTapsRequired = 1
        self.skipImageview.addGestureRecognizer(skip)
        
        self.playImageview.isUserInteractionEnabled = true
        let play: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onPlayBtnClicked(recognizer:)))
        play.numberOfTapsRequired = 1
        self.playImageview.addGestureRecognizer(play)
    }
    
    @objc func onPreviousClicked(recognizer: UIGestureRecognizer) {
        Log.print("onPreviousClicked")
        progressTimer?.invalidate()
        setButtonHideShow(hide: true)
        NotificationCenter.default.post(name: .previousRadioMain, object: nil)
    }
    
    @objc func onPauseClicked(recognizer: UIGestureRecognizer) {
        Log.print("onPauseBtnClicked")
        progressTimer?.invalidate()
        setButtonHideShow(hide: true)
        NotificationCenter.default.post(name: .pauseRadioMain, object: nil)
    }
    
    @objc func onSkipBtnClicked(recognizer: UIGestureRecognizer) {
        Log.print("onSkipBtnClicked")
        progressTimer?.invalidate()
        setButtonHideShow(hide: true)
        NotificationCenter.default.post(name: .skipRadioMain, object: nil)
    }
    
    @objc func onPlayBtnClicked(recognizer: UIGestureRecognizer) {
        Log.print("onPlayBtnClicked")
        progressTimer?.invalidate()
        setButtonHideShow(hide: true)
        NotificationCenter.default.post(name: .startCurrentRadioMain, object: nil)
    }
    
    static func setDefaultValues() {
        HomeViewController.albumArtPath = "http://zerolive7.iptime.org:9093/api/public/dl/CCxak7Jj/01_project/cloudradio/cosmos1.jpeg"
        RadioPlayer.curAlbumUrl = HomeViewController.albumArtPath
        HomeViewController.channelName = "CloudRadio"
        HomeViewController.programName = "OnAir Ready"
    }
    
    func updateLabel() {
        Log.print("updateLabel ch: \(HomeViewController.channelName)  program: \(HomeViewController.programName)")
        
        if ( RadioPlayer.IsRadioPlaying == RadioPlayStatus.initial && YoutubePlayer.PlayingState == .unstarted ) {
            initialLabel.baselineAdjustment = .alignBaselines
            initialLabel.textAlignment = .center
            initialLabel.numberOfLines = 0
            initialLabel.textColor = .white
            initialLabel.font = UIFont.systemFont(ofSize: 25, weight: .bold)
            initialLabel.text = self.initialMessage
            
            programNameLabel.isHidden = true
            channelNameLabel.isHidden = true
            starttimeLabel.isHidden = true
            endtimeLabel.isHidden = true
        } else {
            programNameLabel.isHidden = false
            programNameLabel.baselineAdjustment = .alignBaselines
            programNameLabel.numberOfLines = 0
            programNameLabel.textAlignment = .center
            programNameLabel.textColor = .white
            programNameLabel.font = UIFont.systemFont(ofSize: 30, weight: .bold)
            programNameLabel.text = HomeViewController.programName
            programNameLabel.speed = .duration(10)
            
            channelNameLabel.isHidden = false
            channelNameLabel.baselineAdjustment = .alignBaselines
            channelNameLabel.textAlignment = .center
            channelNameLabel.textColor = .white
            channelNameLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            channelNameLabel.text = HomeViewController.channelName
            
            initialLabel.isHidden = true
        }
    }
    
    func setButtonHideShow(hide: Bool) {
//        Log.print("setButtonHideShow: \(hide)")
        self.previousImageview.isHidden = hide
        self.playImageview.isHidden = hide
        self.pauseImageview.isHidden = hide
        self.skipImageview.isHidden = hide
    }
    
    func showMediaControllButtons() {
//        Log.print("showMediaControllButtons")
        setButtonHideShow(hide: false)
        if ( RadioPlayer.IsRadioPlaying == RadioPlayStatus.playing
             || RadioPlayer.IsRadioPlaying == RadioPlayStatus.live
             || YoutubePlayer.PlayingState == .playing ) {
            self.playImageview.isHidden = true
            self.pauseImageview.isHidden = false
        } else {
            self.playImageview.isHidden = false
            self.pauseImageview.isHidden = true
        }
    }
    
    func showPlayTimeLable(elapsed: Double, duration: Double) {
        starttimeLabel.isHidden = false
        starttimeLabel.baselineAdjustment = .alignBaselines
        starttimeLabel.textAlignment = .center
        starttimeLabel.textColor = .white
        starttimeLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        starttimeLabel.text = CloudRadioUtils.getUTCDateString(timevalue: elapsed)
        
        endtimeLabel.isHidden = false
        endtimeLabel.baselineAdjustment = .alignBaselines
        endtimeLabel.textAlignment = .center
        endtimeLabel.textColor = .white
        endtimeLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        endtimeLabel.text = CloudRadioUtils.getUTCDateString(timevalue: duration)
    }
    
    func updateProgressView() {
        Log.print("updateProgressView")
        if ( RadioPlayer.IsRadioPlaying == RadioPlayStatus.initial
             || RadioPlayer.IsRadioPlaying == RadioPlayStatus.unknown ) {
            setButtonHideShow(hide: true)
            progressView.isHidden = true
            starttimeLabel.isHidden = true
            endtimeLabel.isHidden = true
        }
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(doUpdateProgressBar), userInfo: nil, repeats: true)
        
        updateAlbumArt(path: HomeViewController.albumArtPath)
        updateLabel()
    }
    
    @objc func doUpdateProgressBar(timer: Timer) {
        let bLiveChannel = RadioChannelResources.checkLiveChannel(channelName: RadioPlayer.curChannelName)
        
        if ( RadioPlayer.IsRadioPlaying == RadioPlayStatus.live
            || (bLiveChannel && RadioPlayer.IsRadioPlaying == RadioPlayStatus.paused) ) {
            progressView.progressViewStyle = .bar
            progressView.progressTintColor = #colorLiteral(red: 0.9848453403, green: 0.9296768308, blue: 0.7754012942, alpha: 1)
            progressView.trackTintColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            progressView.progress = 1.0
            progressView.isHidden = false
            showMediaControllButtons()
        } else {
            var duration: Double? = 0
            var elapsed: Double? = 0
            
            if YoutubePlayer.PlayingState == .playing
                || YoutubePlayer.PlayingState == .paused {
                duration = YoutubePlayer.getDurationTime()
                elapsed = YoutubePlayer.getPlayTime()
            } else {
                guard let starttime = RadioPlayer.curPlayTimeInfo?.starttime else {
                    Log.print("doUpdateProgressBar: starttime invalid ytState: \(YoutubePlayer.PlayingState)")
                    progressView.isHidden = true
                    setButtonHideShow(hide: true)
                    starttimeLabel.isHidden = true
                    endtimeLabel.isHidden = true
                    if YoutubePlayer.PlayingState == .unstarted {
                        progressTimer?.invalidate()
                    }
                    return
                }
                
                guard let endtime = RadioPlayer.curPlayTimeInfo?.endtime else {
                    Log.print("doUpdateProgressBar: endtime invalid")
                    progressView.isHidden = true
                    setButtonHideShow(hide: true)
                    starttimeLabel.isHidden = true
                    endtimeLabel.isHidden = true
                    if YoutubePlayer.PlayingState == .unstarted {
                        progressTimer?.invalidate()
                    }
                    return
                }
                let starttimeSec = starttime + ":00"
                let endtimeSec = endtime + ":00"
                duration = CloudRadioUtils.getDuration(startTime: starttimeSec, endTime: endtimeSec)
                elapsed = CloudRadioUtils.getElapsedWith(startTime: starttimeSec)
            }

            guard let duration = duration else { return }
            guard let elapsed = elapsed else { return }
            
            let percent = CloudRadioUtils.getPercentProgress(elapsed: elapsed, duration: duration)

    //        Log.print("doUpdateProgressBar percent: \(percent)")
            progressView.progressViewStyle = .bar
            progressView.progressTintColor = #colorLiteral(red: 0.9848453403, green: 0.9296768308, blue: 0.7754012942, alpha: 1)
            progressView.trackTintColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            progressView.progress = percent
            progressView.isHidden = false

            showMediaControllButtons()
            showPlayTimeLable(elapsed: elapsed, duration: duration)
            
            if ( RadioPlayer.IsRadioPlaying != RadioPlayStatus.playing && YoutubePlayer.PlayingState != .playing) {
                Log.print("Finish progressView update! It's not playing state")
                progressTimer?.invalidate()
            }
            
            if ( percent == 1.0 ) {
                Log.print("progressbar finish!")
                showPlayTimeLable(elapsed: duration, duration: duration )
                progressTimer?.invalidate()
            }
        }
    }
    
    func updateAlbumArt(path: String) {
        Log.print("updateAlbumArt path: \(path)")
        self.albumImageView.isHidden = false

        if CloudRadioShareValues.TYPE == .YOUTUBEPLAYLIST {
            if YoutubePlayer.PlayingState == .buffering
                || YoutubePlayer.PlayingState == .paused
                || YoutubePlayer.PlayingState == .playing {
                NotificationCenter.default.post(name: .setVideoViewIsHiddenMain, object: false)
                self.albumImageView.isHidden = true
            }
        } else {
            NotificationCenter.default.post(name: .setVideoViewIsHiddenMain, object: true)
            albumImageView.downloaded(from: path)
        }
//        albumImageView.downloaded(from: path)
    }
}
