//
//  ContainerViewController.swift
//  CustomSideMenuiOSExample
//
//  Created by John Codeos on 2/8/21.
//

import SafariServices
import UIKit
import AVKit

struct PlayInfo {
    var channelName: String
    var channelPLSAddress: String
    var channelCode: Int
}

protocol RadioPlayerDelegate {
    func setupAudioSession()
    func startRadio(channelName: String, channelPLSAddress: String)
    func isPlaying() -> Bool
    func stopRadio()
    func pauseRadio()
    func playRadio(channelName: String, channelUrl: URL)
    func startKBSRadio(channelName: String, channelCode: Int )
    func startNormalRadio(channelName: String, address: String)
    func startTBFMSRadio(channelName: String, channelPLSAddress: String)
    func getPlayingState() -> RadioPlayStatus
    func setupRemoteCommandCenter()
}

extension Notification.Name {
    static let startRadioMain = Notification.Name("startRadioMain")
    static let startCurrentRadioMain = Notification.Name("startCurrentRadioMain")
    static let pauseRadioMain = Notification.Name("pauseRadioMain")
    static let previousRadioMain = Notification.Name("previousRadioMain")
    static let skipRadioMain = Notification.Name("skipRadioMain")
    static let stopRadioMain = Notification.Name("stopRadioMain")
    static let isPlayingQueryMain = Notification.Name("isPlayingQueryMain")
    static let isPlayingAnswerHome = Notification.Name("isPlayingAnswerHome")
    static let updateAlbumArtMain = Notification.Name("updateAlbumArtMain")
    static let startRadioTimerMain = Notification.Name("startRadioTimerMain")
    static let stopRadioTimerMain = Notification.Name("stopRadioTimerMain")
    static let callTestTimeSettingMain = Notification.Name("callTestTimeSettingMain")
    static let startRadioTimerSettingsMain = Notification.Name("startRadioTimerSettingsMain")
    static let stopRadioTimerSettingsMain = Notification.Name("stopRadioTimerSettingsMain")
    static let updateSideMenu = Notification.Name("updateSideMenu")
    
    static let updateAlbumArtMainYT = Notification.Name("updateAlbumArtMainYT")
    static let showAwesomeAlert = Notification.Name("showAwesomeAlert")
    
    static let closeSettingView = Notification.Name("closeSettingView")
}

class MainViewController: UIViewController {
    private var sideMenuViewController: SideMenuViewController!
    private var homeMenuViewcontroller: UIViewController? = nil
    private var sideMenuShadowView: UIView!
    private var sideMenuRevealWidth: CGFloat = 260
    private let paddingForRotation: CGFloat = 150
    private var isExpanded: Bool = false
    private var draggingIsEnabled: Bool = false
    private var panBaseLocation: CGFloat = 0.0
    
    // Expand/Collapse the side menu by changing trailing's constant
    private var sideMenuTrailingConstraint: NSLayoutConstraint!

    private var revealSideMenuOnTop: Bool = true
    
    var gestureEnabled: Bool = true
    
    var playerDelegate: RadioPlayerDelegate?
    
    static var currentChannelIdx: Int = -1
    var mainRadioTimer: Timer?
    var programRadioTimer: Timer?
    
    var settingRadioTimer: Timer?

    var currentSceneIndex: Int = 0
    
    let youtubePlayer = YoutubePlayer()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        // load specialFeatures
        if let settingValue = CloudRadioUtils.loadSettings(){
            Log.print("Found settings json")
            CloudRadioShareValues.IsUnlockedFeature = settingValue.isUnlocked
            CloudRadioShareValues.IsShuffle = settingValue.isShuffle
            CloudRadioShareValues.IsRepeat = settingValue.isRepeat
            
            if ( CloudRadioShareValues.IsUnlockedFeature ) {
                Log.print("Making awesome")
                CloudRadioShareValues.versionString = CloudRadioShareValues.versionString + " (Awesome!)"
            }
        } else {
            Log.print("Can't load setting json.")
        }
        
        // youtubePlayer
        youtubePlayer.initialize()
        youtubePlayer.setupAudioSession()
                
        // Shadow Background View
        self.sideMenuShadowView = UIView(frame: self.view.bounds)
        self.sideMenuShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.sideMenuShadowView.backgroundColor = .black
        self.sideMenuShadowView.alpha = 0.0
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TapGestureRecognizer))
        tapGestureRecognizer.numberOfTapsRequired = 1
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
        if self.revealSideMenuOnTop {
            view.insertSubview(self.sideMenuShadowView, at: 1)
        }

        // Side Menu
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        self.sideMenuViewController = storyboard.instantiateViewController(withIdentifier: "SideMenuID") as? SideMenuViewController
        self.sideMenuViewController.defaultHighlightedCell = 999 // Default Highlighted Cell
        self.sideMenuViewController.delegate = self
        view.insertSubview(self.sideMenuViewController!.view, at: self.revealSideMenuOnTop ? 2 : 0)
        addChild(self.sideMenuViewController!)
        self.sideMenuViewController!.didMove(toParent: self)

        // Side Menu AutoLayout

        self.sideMenuViewController.view.translatesAutoresizingMaskIntoConstraints = false

        if self.revealSideMenuOnTop {
            self.sideMenuTrailingConstraint = self.sideMenuViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -self.sideMenuRevealWidth - self.paddingForRotation)
            self.sideMenuTrailingConstraint.isActive = true
        }
        NSLayoutConstraint.activate([
            self.sideMenuViewController.view.widthAnchor.constraint(equalToConstant: self.sideMenuRevealWidth),
            self.sideMenuViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.sideMenuViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        // Side Menu Gestures
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)

        // Default Main View Controller
        showHomeViewController(viewController: UINavigationController.self, storyboardId: "HomeNavID")
        
        // player setting
        self.playerDelegate = RadioPlayer()
        self.playerDelegate?.setupAudioSession()
        
        NotificationCenter.default.addObserver(self, selector: #selector(startRadioMain(_:)), name: .startRadioMain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startCurrentRadioMain(_:)), name: .startCurrentRadioMain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRadioMain(_:)), name: .stopRadioMain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pauseRadioMain(_:)), name: .pauseRadioMain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(previousRadioMain(_:)), name: .previousRadioMain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(skipRadioMain(_:)), name: .skipRadioMain, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(isPlayingRadioMain(_:)), name: .isPlayingQueryMain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateAlbumArtMain(_:)), name: .updateAlbumArtMain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startRadioTimerMain(_:)), name: .startRadioTimerMain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopRadioTimerMain(_:)), name: .stopRadioTimerMain, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateAlbumArtMainYT(_:)), name: .updateAlbumArtMainYT, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(callTestTimeSettingMain(_:)), name: .callTestTimeSettingMain, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(stopRadioTimerSettingsMain(_:)), name: .stopRadioTimerSettingsMain, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(startRadioTimerSettingsMain(_:)), name: .startRadioTimerSettingsMain, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateSideMenuMain(_:)), name: .updateSideMenu, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(showAwesomeAlertMain(_:)), name: .showAwesomeAlert, object: nil)

        DispatchQueue.global().async {
            self.playerDelegate?.setupRemoteCommandCenter()
        }
        
        // Detect into background
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.didBecomeActiveNotification, object: nil)

        
        Log.print(">>> MainViewController viewDidend")
    }
    
    @objc func appMovedToBackground() {
        Log.print("App moved to background!")
        CloudRadioShareValues.IsLockScreen = true
        CloudRadioShareValues.LockedPlay = false
    }
    
    @objc func appMovedToForeground() {
        Log.print("App moved to foreground!")
        CloudRadioShareValues.IsLockScreen = false
    }
    
    @objc func showAwesomeAlertMain(_ notification: NSNotification) {
        Log.print("showAwesomeAlertMain")
        let alert = UIAlertController(title: "Awesome", message: "이제 모든 기능을 사용할 수 있습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func startRadioTimerSettingsMain(_ notification: NSNotification) {
        Log.print("startRadioTimerSettingsMain")
        self.settingRadioTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(requestStopRadio), userInfo: nil, repeats: true)
    }
    
    @objc func requestStopRadio(timer: Timer) {
        CloudRadioShareValues.stopRadioTimerTime -= 1
        if ( CloudRadioShareValues.stopRadioTimerTime > 0 ) {
            Log.print("stopRadio Timer  onGoing ~ \(CloudRadioUtils.getUTCDateString(timevalue: CloudRadioShareValues.stopRadioTimerTime))")
        } else {
            Log.print("STOP RADIO ~ !!!")
            Log.print("STOP RADIO ~ !!!")
            Log.print("STOP RADIO ~ !!!")
            NotificationCenter.default.post(name: .stopRadioMain, object: nil)
            self.settingRadioTimer?.invalidate()
            self.settingRadioTimer = nil
        }
    }
    
    @objc func stopRadioTimerSettingsMain(_ notification: NSNotification) {
        Log.print("stopRadioTimerSettingsMain")
        if ( self.settingRadioTimer?.isValid ) != nil {
            self.settingRadioTimer?.invalidate()
            self.settingRadioTimer = nil
        }
    }
    
    @objc func startRadioTimerMain(_ notification: NSNotification) {
        var timeintervalvalue = 0.0
        
        if ( RadioPlayer.curPlayTimeInfo?.interval != nil ) {
            timeintervalvalue = RadioPlayer.curPlayTimeInfo!.interval
        }
        
        stopAllTimer()
        
        guard self.mainRadioTimer == nil else {
            Log.print("(ERROR) mainRadioTimer is working")
            return
        }
        
        DispatchQueue.main.async
        {
            if timeintervalvalue > 0  {
                Log.print(">>>>> mainRadioTimer start interval(\(timeintervalvalue)) now(\(CloudRadioUtils.getNowtimeStringSeconds()))")
                self.mainRadioTimer = Timer.scheduledTimer(timeInterval: timeintervalvalue, target: self, selector: #selector(self.programFinish), userInfo: nil, repeats: false)
            } else {
                Log.print("Invalid interval")
                timeintervalvalue = 5
                Log.print(">>>>> mainRadioTimer start interval(\(timeintervalvalue)) now(\(CloudRadioUtils.getNowtimeStringSeconds()))")
                self.mainRadioTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.programFinish), userInfo: nil, repeats: false)
            }
        }
    }
    
    func stopAllTimer() {
        Log.print("stopALLTimer ~!")
        if (( self.mainRadioTimer?.isValid ) != nil) {
            Log.print("XXXXX stopAllTimer: mainTimer")
            self.mainRadioTimer?.invalidate()
            self.mainRadioTimer = nil
        }
        if (( self.programRadioTimer?.isValid ) != nil) {
            Log.print("XXXXX stopAllTimer: programTimer")
            self.programRadioTimer?.invalidate()
            self.programRadioTimer = nil
        }
    }
    
    @objc func stopRadioTimerMain(_ notification: NSNotification) {
        Log.print("stopRadioTimerMain")
        stopAllTimer()
    }
    
    @objc func programFinish(timer: Timer) {
        Log.print("programFinish.")
        if (( self.mainRadioTimer?.isValid ) != nil) {
            Log.print("XXXXX programFinish. stop mainRadioTimer")
            self.mainRadioTimer?.invalidate()
            self.mainRadioTimer = nil
        }
        guard self.programRadioTimer == nil else {
            Log.print("(ERROR) programRadioTimer is working")
            return
        }
        DispatchQueue.main.async
        {
            Log.print(">>>>> start programRadioTimer! with 5 sec (repeat true)")
            self.programRadioTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.doProgramRefresh), userInfo: nil, repeats: true)
        }
    }
    
    @objc func doProgramRefresh(timer: Timer) {
        Log.print("doProgramRefresh called at [\(CloudRadioUtils.getNowtimeStringSeconds())]")

        if ( RadioPlayer.curChannelName.contains("SBS") ) {
            Log.print("Change SBS LangTypes!")
            RadioChannelResources.changeSBSLangType()
        }
        
        RadioPlayer.setAlbumArtPrepare(channelName: RadioPlayer.curChannelName, isPlaying: true)
//        Log.print("TEST CALL")
//        self.TEST_FOR_TIMER()
        
        RadioPlayer.setNowPlayingInfo(channelName: RadioPlayer.curChannelName, programName: RadioPlayer.curProgramName, toPlay: true)
        // test
        guard let url = RadioPlayer.curAlbumUrl else {
            Log.print("Album url is invalid.")
            return
        }
        HomeViewController.albumArtPath = url
        
        // refresh home view over than 10 seconds
        guard let interval = RadioPlayer.curPlayTimeInfo?.interval else {
            Log.print("interval is invalid.")
            return
        }
        Log.print("doProgramRefresh interval: \(interval)")

        if interval > 10 {
            showHomeMenu()
            if (( self.programRadioTimer?.isValid ) != nil) {
                Log.print("XXXXX stop ProgramTimer")
                self.programRadioTimer?.invalidate()
                self.programRadioTimer = nil
                // FOR TEST
//                NotificationCenter.default.post(name: .callTestTimeSettingMain, object: nil)
            }
        }
    }
    
    @objc func callTestTimeSettingMain(_ notificatoin: NSNotification) {
        self.TEST_FOR_TIMER()
        NotificationCenter.default.post(name: .startRadioTimerMain, object: RadioPlayer.curPlayTimeInfo)
    }
    
    func TEST_FOR_TIMER() {
        let starttime = CloudRadioUtils.getDifftimeString(diffSecond: -90)
        let endtime =  CloudRadioUtils.getDifftimeString(diffSecond: 90)
        let nowtime = CloudRadioUtils.getNowtimeString()
        Log.print("start(\(starttime)) ~ now(\(nowtime)) ~ end(\(endtime))")
        let radioTimeInfo = RadioTimeInfo(starttime: String(starttime), endtime: String(endtime), interval: CloudRadioUtils.getDifftimeSecondForEndtime(endTime: String(endtime)))
        RadioPlayer.curPlayTimeInfo = radioTimeInfo
    }
    
    @objc func updateAlbumArtMain(_ notification: NSNotification) {
        guard let url = RadioPlayer.curAlbumUrl else { return }
        HomeViewController.albumArtPath = url
        Log.print("updateAlbumArtMain(): \(HomeViewController.albumArtPath)")
        showHomeMenu()
    }
    
    @objc func updateAlbumArtMainYT(_ notification: NSNotification) {
        guard let url = youtubePlayer.curAlbumUrl else { return }
        HomeViewController.albumArtPath = url
        Log.print("updateAlbumArtMainYT(): \(HomeViewController.albumArtPath)")
        showHomeMenu()
    }
    
    @objc func isPlayingRadioMain(_ notification: NSNotification) {
        Log.print("isPlayingRadioMain")
        let isPlaying = self.playerDelegate?.getPlayingState()
        NotificationCenter.default.post(name: .isPlayingAnswerHome, object: isPlaying)
    }
    
    @objc func pauseRadioMain(_ notification: NSNotification) {
        Log.print("pauseRadioMain")

        if YoutubePlayer.IsYoutubePlaying == .playing {
            self.youtubePlayer.pauseVideo()
            self.youtubePlayer.updateVideoInfo()
        } else {
            self.playerDelegate?.pauseRadio()
        }
    }
    
    @objc func previousRadioMain(_ notification: NSNotification) {
        if YoutubePlayer.IsYoutubePlaying == .playing || YoutubePlayer.IsYoutubePlaying == .paused {
            self.youtubePlayer.setCurrentVideoIndex(direction: .PREV)
            self.youtubePlayer.requestNextVideo()
        } else {
            var info: PlayInfo? = nil
            var curIdx = MainViewController.currentChannelIdx
            let menuCount = sideMenuViewController.sideMenuData.menuMirror.count
            
            Log.print("cur) Idx(\(curIdx)/\(menuCount-1)) - channelName(\(sideMenuViewController.sideMenuData.menuMirror[curIdx].title))")
            if ( curIdx == 0 ) {
                curIdx = (menuCount-1)
            } else {
                curIdx-=1
            }
            Log.print("next) Idx(\(curIdx)/\(menuCount-1)) - channelName(\(sideMenuViewController.sideMenuData.menuMirror[curIdx].title))")

            updateSideMenu(idx: curIdx)
            
            // check if next is youtube or not
            if sideMenuViewController.sideMenuData.menuMirror[curIdx].type == .YOUTUBEPLAYLIST {
                youtubePlayer.playlistName = sideMenuViewController.sideMenuData.menuMirror[curIdx].title
                youtubePlayer.playlistId = sideMenuViewController.sideMenuData.menuMirror[curIdx].playlistId
                NotificationCenter.default.post(name: .stopRadioMain, object: nil)
            } else {
                let title = sideMenuViewController.sideMenuData.menuMirror[curIdx].title
                info = RadioChannelResources.getChannel(title: title)
                NotificationCenter.default.post(name: .startRadioMain, object: info)
            }
        }
    }
    
    @objc func skipRadioMain(_ notification: NSNotification) {
        if YoutubePlayer.IsYoutubePlaying == .playing || YoutubePlayer.IsYoutubePlaying == .paused {
            self.youtubePlayer.setCurrentVideoIndex(direction: .NEXT)
            self.youtubePlayer.requestNextVideo()
        } else {
            var info: PlayInfo? = nil
            var curIdx = MainViewController.currentChannelIdx
            let menuCount = sideMenuViewController.sideMenuData.menuMirror.count
            
            Log.print("cur) Idx(\(curIdx)/\(menuCount-1)) - channelName(\(sideMenuViewController.sideMenuData.menuMirror[curIdx].title))")
            if ( curIdx == (menuCount-1) ) {
                curIdx = 0
            } else {
                curIdx+=1
            }
            Log.print("next) Idx(\(curIdx)/\(menuCount-1)) - channelName(\(sideMenuViewController.sideMenuData.menuMirror[curIdx].title))")
            
            updateSideMenu(idx: curIdx)

            // check if next is youtube or not
            if sideMenuViewController.sideMenuData.menuMirror[curIdx].type == .YOUTUBEPLAYLIST {
                youtubePlayer.playlistName = sideMenuViewController.sideMenuData.menuMirror[curIdx].title
                youtubePlayer.playlistId = sideMenuViewController.sideMenuData.menuMirror[curIdx].playlistId
                NotificationCenter.default.post(name: .stopRadioMain, object: nil)
            } else {
                let title = sideMenuViewController.sideMenuData.menuMirror[curIdx].title
                info = RadioChannelResources.getChannel(title: title)
                NotificationCenter.default.post(name: .startRadioMain, object: info)
            }
        }
    }
    
    @objc func stopRadioMain(_ notification: NSNotification) {
        Log.print("stopRadioMain")
        
        stopAllTimer()
        
        CloudRadioShareValues.stopRadioTimerTime = 0
        CloudRadioShareValues.stopRadioSwitchisOn = false
        CloudRadioShareValues.stopRadioTimerisActive = false
        CloudRadioShareValues.requestStopRadioTimer()
        
//        MainViewController.currentChannelIdx = -1
        self.playerDelegate?.stopRadio()
        
        if ( YoutubePlayer.IsYoutubePlaying == .playing ) {
            Log.print("do Stop Youtube")
            youtubePlayer.stopVideo()
        }
    }
    
    @objc func startCurrentRadioMain(_ notification: NSNotification) {
        Log.print("startCurrentRadioMain")

        if YoutubePlayer.IsYoutubePlaying == .paused {
            self.youtubePlayer.resumeVideo()
            self.youtubePlayer.updateVideoInfo()
        } else {
            self.playerDelegate?.playRadio(channelName: RadioPlayer.curChannelName, channelUrl: RadioPlayer.curChannelUrl!)
        }
    }
    
    @objc func startRadioMain(_ notification: NSNotification) {
        if let info = notification.object as? PlayInfo {
            Log.print("startRadioMain: \(info.channelName), channelCode: \(info.channelCode)")
            
            RadioPlayer.curPlayInfo = nil
            RadioPlayer.curPlayInfo = info
            
            // kbs has own channel code
            if ( info.channelCode != 0 ) {
                self.playerDelegate?.startKBSRadio(channelName: info.channelName, channelCode: info.channelCode)
            } else {
                if ( info.channelName.contains("TBS") ) {
                    // url use address directly without parsing
                    self.playerDelegate?.startTBFMSRadio(channelName: info.channelName, channelPLSAddress: info.channelPLSAddress)
                } else {
                    self.playerDelegate?.startRadio(channelName: info.channelName, channelPLSAddress: info.channelPLSAddress)
                }
            }
        }
    }
    
    func showHomeMenu() {
        DispatchQueue.main.async {
            self.sideMenuState(expanded: false)
            self.showHomeViewController(viewController: UINavigationController.self, storyboardId: "HomeNavID")
        }
    }
    
    @objc func updateSideMenuMain(_ notification: NSNotification) {
        if let idx = notification.object as? Int {
            Log.print("updateSideMenu idx: \(idx)")
            updateSideMenu(idx: idx)
        } else {
            Log.print("updateSideMenu is failed. wrong idx")
        }
    }
    
    func updateSideMenu(idx: Int) {
        MainViewController.currentChannelIdx = idx
        
        for subview in view.subviews {
            if subview.tag == 999 {
                Log.print("- updateSideMenu() Remove subviews -")
                self.sideMenuViewController.willMove(toParent: nil)
                self.sideMenuViewController.removeFromParent()
                subview.removeFromSuperview()
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        self.sideMenuViewController = storyboard.instantiateViewController(withIdentifier: "SideMenuID") as? SideMenuViewController
        self.sideMenuViewController.defaultHighlightedCell = idx
        self.sideMenuViewController.delegate = self
        
        self.sideMenuViewController!.view.tag = 999
        
        view.insertSubview(self.sideMenuViewController!.view, at: self.revealSideMenuOnTop ? 2 : 0)
        addChild(self.sideMenuViewController!)
        self.sideMenuViewController!.didMove(toParent: self)
//        self.sideMenuViewController.sideMenuTableView.reloadData()
        // Side Menu AutoLayout
        self.sideMenuViewController.view.translatesAutoresizingMaskIntoConstraints = false

        if self.revealSideMenuOnTop {
            self.sideMenuTrailingConstraint = self.sideMenuViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -self.sideMenuRevealWidth - self.paddingForRotation)
            self.sideMenuTrailingConstraint.isActive = true
        }
        NSLayoutConstraint.activate([
            self.sideMenuViewController.view.widthAnchor.constraint(equalToConstant: self.sideMenuRevealWidth),
            self.sideMenuViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            self.sideMenuViewController.view.topAnchor.constraint(equalTo: view.topAnchor)
        ])

        // Side Menu Gestures
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }

    // Keep the state of the side menu (expanded or collapse) in rotation
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            if self.revealSideMenuOnTop {
                self.sideMenuTrailingConstraint.constant = self.isExpanded ? 0 : (-self.sideMenuRevealWidth - self.paddingForRotation)
            }
        }
    }

    func animateShadow(targetPosition: CGFloat) {
        UIView.animate(withDuration: 0.5) {
            // When targetPosition is 0, which means side menu is expanded, the shadow opacity is 0.6
            self.sideMenuShadowView.alpha = (targetPosition == 0) ? 0.6 : 0.0
        }
    }

    // Call this Button Action from the View Controller you want to Expand/Collapse when you tap a button
    @IBAction open func revealSideMenu() {
        self.sideMenuState(expanded: self.isExpanded ? false : true)
    }

    func sideMenuState(expanded: Bool) {
        Log.print("sideMenuState: \(expanded)")

        if expanded {
            self.animateSideMenu(targetPosition: self.revealSideMenuOnTop ? 0 : self.sideMenuRevealWidth) { _ in
                self.isExpanded = true
            }
            // Animate Shadow (Fade In)
            UIView.animate(withDuration: 0.5) { self.sideMenuShadowView.alpha = 0.6 }
        }
        else {
            self.animateSideMenu(targetPosition: self.revealSideMenuOnTop ? (-self.sideMenuRevealWidth - self.paddingForRotation) : 0) { _ in
                self.isExpanded = false
            }
            // Animate Shadow (Fade Out)
            UIView.animate(withDuration: 0.5) { self.sideMenuShadowView.alpha = 0.0 }
            
            NotificationCenter.default.post(name: Notification.Name("finishEdit"), object: nil)
        }
    }
    
    func animateSideMenu(targetPosition: CGFloat, completion: @escaping (Bool) -> ()) {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0, options: .layoutSubviews, animations: {
            if self.revealSideMenuOnTop {
                self.sideMenuTrailingConstraint.constant = targetPosition
                self.view.layoutIfNeeded()
            }
            else {
                self.view.subviews[1].frame.origin.x = targetPosition
            }
        }, completion: completion)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

extension MainViewController: SideMenuViewControllerDelegate {
    func returnHomeScene() {
        self.currentSceneIndex = 0
        self.showHomeViewController(viewController: UINavigationController.self, storyboardId: "HomeNavID")
        // Collapse side menu with animation
        DispatchQueue.main.async { self.sideMenuState(expanded: false) }
    }
    
    func showSettingsScene() {
        Log.print("showSettingsScene")
        self.currentSceneIndex = 1
        // Settings
//        self.showViewController(viewController: UINavigationController.self, storyboardId: "SettingsNavID")

        
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        let settionModalVC = storyboard.instantiateViewController(withIdentifier: "SettingsNavID") as? SettingsViewController
        present(settionModalVC!, animated: true, completion: nil)
        
        // Collapse side menu with animation
        DispatchQueue.main.async { self.sideMenuState(expanded: false) }
    }
    
    func selectedCell(_ row: Int, title: String) {

        Log.print("selectedCell curChIdx(\(row)) self.currentSceneIndex(\(self.currentSceneIndex))")
        // Collapse side menu with animation
        DispatchQueue.main.async {
            self.sideMenuState(expanded: false)
            if self.currentSceneIndex != 0 {
                self.currentSceneIndex = 0
                self.showHomeViewController(viewController: UINavigationController.self, storyboardId: "HomeNavID")
            }
        }

        // TODO
        // Implment play youtube
        if ( MainViewController.currentChannelIdx != row  ) {
            if !sideMenuViewController.sideMenuData.menuMirror.isEmpty {
                if sideMenuViewController.sideMenuData.menuMirror[row].type == .YOUTUBEPLAYLIST {
                    Log.print("start youtube ID: \(sideMenuViewController.sideMenuData.menuMirror[row].playlistId)")
                    MainViewController.currentChannelIdx = row
                    
                    // do download playlist first
                    // After download finish, playYoutube will call automatically
                    youtubePlayer.playlistName = sideMenuViewController.sideMenuData.menuMirror[row].title
                    youtubePlayer.playlistId = sideMenuViewController.sideMenuData.menuMirror[row].playlistId
                    NotificationCenter.default.post(name: .stopRadioMain, object: nil)
                    return
                }
            }
            
            let info = RadioChannelResources.getChannel(title: title)
            MainViewController.currentChannelIdx = row
            Log.print("start radio: \(String(describing: info?.channelName))")
            NotificationCenter.default.post(name: .startRadioMain, object: info)
        }
    }

    func showHomeViewController<T: UIViewController>(viewController: T.Type, storyboardId: String) -> () {
        // Remove the previous View
        for subview in view.subviews {
            if subview.tag == 99 {
                Log.print("- showViewController() Remove subviews -")
                self.homeMenuViewcontroller?.willMove(toParent: nil)
                self.homeMenuViewcontroller?.removeFromParent()
                subview.removeFromSuperview()
            }
        }
        
        
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        guard let vc = storyboard.instantiateViewController(withIdentifier: storyboardId) as? T else {
            Log.print("Can't get home nav view")
            return
        }
        self.homeMenuViewcontroller = vc
        self.homeMenuViewcontroller!.view.tag = 99
        view.insertSubview(self.homeMenuViewcontroller!.view, at: self.revealSideMenuOnTop ? 0 : 1)
        addChild(self.homeMenuViewcontroller!)
        if !self.revealSideMenuOnTop {
            if isExpanded {
                self.homeMenuViewcontroller!.view.frame.origin.x = self.sideMenuRevealWidth
            }
            if self.sideMenuShadowView != nil {
                self.homeMenuViewcontroller!.view.addSubview(self.sideMenuShadowView)
            }
        }
        self.homeMenuViewcontroller!.didMove(toParent: self)
    }
}

extension MainViewController: UIGestureRecognizerDelegate {
    @objc func TapGestureRecognizer(sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            if self.isExpanded {
                self.sideMenuState(expanded: false)
            }
        }
    }

    // Close side menu when you tap on the shadow background view
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if (touch.view?.isDescendant(of: self.sideMenuViewController.view))! {
            return false
        }
        return true
    }
    
    // Dragging Side Menu
    @objc private func handlePanGesture(sender: UIPanGestureRecognizer) {
        
        guard gestureEnabled == true else { return }

        let position: CGFloat = sender.translation(in: self.view).x
        let velocity: CGFloat = sender.velocity(in: self.view).x

        switch sender.state {
        case .began:

            // If the user tries to expand the menu more than the reveal width, then cancel the pan gesture
            if velocity > 0, self.isExpanded {
                sender.state = .cancelled
            }

            // If the user swipes right but the side menu hasn't expanded yet, enable dragging
            if velocity > 0, !self.isExpanded {
                self.draggingIsEnabled = true
            }
            // If user swipes left and the side menu is already expanded, enable dragging
            else if velocity < 0, self.isExpanded {
                self.draggingIsEnabled = true
            }

            if self.draggingIsEnabled {
                // If swipe is fast, Expand/Collapse the side menu with animation instead of dragging
                let velocityThreshold: CGFloat = 550
                if abs(velocity) > velocityThreshold {
                    self.sideMenuState(expanded: self.isExpanded ? false : true)
                    self.draggingIsEnabled = false
                    return
                }

                if self.revealSideMenuOnTop {
                    self.panBaseLocation = 0.0
                    if self.isExpanded {
                        self.panBaseLocation = self.sideMenuRevealWidth
                    }
                }
            }

        case .changed:

            // Expand/Collapse side menu while dragging
            if self.draggingIsEnabled {
                if self.revealSideMenuOnTop {
                    // Show/Hide shadow background view while dragging
                    let xLocation: CGFloat = self.panBaseLocation + position
                    let percentage = (xLocation * 150 / self.sideMenuRevealWidth) / self.sideMenuRevealWidth

                    let alpha = percentage >= 0.6 ? 0.6 : percentage
                    self.sideMenuShadowView.alpha = alpha

                    // Move side menu while dragging
                    if xLocation <= self.sideMenuRevealWidth {
                        self.sideMenuTrailingConstraint.constant = xLocation - self.sideMenuRevealWidth
                    }
                }
                else {
                    if let recogView = sender.view?.subviews[1] {
                        // Show/Hide shadow background view while dragging
                        let percentage = (recogView.frame.origin.x * 150 / self.sideMenuRevealWidth) / self.sideMenuRevealWidth

                        let alpha = percentage >= 0.6 ? 0.6 : percentage
                        self.sideMenuShadowView.alpha = alpha

                        // Move side menu while dragging
                        if recogView.frame.origin.x <= self.sideMenuRevealWidth, recogView.frame.origin.x >= 0 {
                            recogView.frame.origin.x = recogView.frame.origin.x + position
                            sender.setTranslation(CGPoint.zero, in: view)
                        }
                    }
                }
            }
        case .ended:
            self.draggingIsEnabled = false
            // If the side menu is half Open/Close, then Expand/Collapse with animation
            if self.revealSideMenuOnTop {
                let movedMoreThanHalf = self.sideMenuTrailingConstraint.constant > -(self.sideMenuRevealWidth * 0.5)
                self.sideMenuState(expanded: movedMoreThanHalf)
            }
            else {
                if let recogView = sender.view?.subviews[1] {
                    let movedMoreThanHalf = recogView.frame.origin.x > self.sideMenuRevealWidth * 0.5
                    self.sideMenuState(expanded: movedMoreThanHalf)
                }
            }
        default:
            break
        }
    }
}

extension UIViewController {
    
    
    
    // With this extension you can access the MainViewController from the child view controllers.
    func revealViewController() -> MainViewController? {
        var viewController: UIViewController? = self
        
        if viewController != nil && viewController is MainViewController {
            return viewController! as? MainViewController
        }
        while (!(viewController is MainViewController) && viewController?.parent != nil) {
            viewController = viewController?.parent
        }
        if viewController is MainViewController {
            return viewController as? MainViewController
        }
        return nil
    }
}
