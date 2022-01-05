//
//  RadioPlayer.swift
//  cloudRadio
//
//  Created by zerolive on 2021/11/19.
//

import Foundation
import Alamofire
import AVKit
import MediaPlayer
import Kanna

enum RadioPlayStatus {
case initial, playing, stopped, paused, live, unknown
}

class RadioPlayer {
    static var bPlaying: Bool = false
    var player: AVPlayer? = nil
    var curUrl: URL? = nil
    var audioSession: AVAudioSession? = nil
    
    // current playing info
    static var curChannelName: String = "CloudRadio"
    static var curProgramName: String = "OnAir Ready"
    static var curChannelUrl: URL? = nil
    static var curAlbumImg: UIImage? = nil
    static var curAlbumUrl: String? = nil
    static var curPlayTimeInfo: RadioTimeInfo? = nil
    static var IsRadioPlaying: RadioPlayStatus = RadioPlayStatus.initial
    static var curPlayInfo: PlayInfo? = nil

    func setRadioPlayerDefaultValues() {
        RadioPlayer.curChannelName = "CloudRadio"
        RadioPlayer.curProgramName = "OnAir Ready"
        RadioPlayer.curAlbumUrl = nil
        RadioPlayer.curChannelUrl = nil
        RadioPlayer.curAlbumImg = nil
        RadioPlayer.curPlayTimeInfo = nil
        RadioPlayer.curPlayInfo = nil
    }
    
    func stopRadio()
    {
        Log.print("stopRadio")
        self.enableRemoteCommandCenter(enable: false)

        self.setRadioPlayerDefaultValues()

        RadioPlayer.setNowPlayingInfo(channelName: RadioPlayer.curChannelName, programName: RadioPlayer.curProgramName, toPlay: false)
        
        HomeViewController.setDefaultValues()
        NotificationCenter.default.post(name: .updateAlbumArtMain, object: nil)
        NotificationCenter.default.post(name: .stopRadioTimerMain, object: nil)

        self.player?.pause()
        RadioPlayer.IsRadioPlaying = RadioPlayStatus.stopped
    }
    
    func pauseRadio()
    {
        Log.print("pauseRadio")
        RadioPlayer.setAlbumArtPrepare(channelName: RadioPlayer.curChannelName, isPlaying: true)
        RadioPlayer.setNowPlayingInfo(channelName: RadioPlayer.curChannelName, programName: RadioPlayer.curProgramName, toPlay: false)
        self.player?.pause()
        RadioPlayer.IsRadioPlaying = RadioPlayStatus.paused
        NotificationCenter.default.post(name: .updateAlbumArtMain, object: nil)
    }
    
    func playRadio(channelName: String, channelUrl: URL)
    {
        if ( self.isPlaying() ) {
            RadioPlayer.curPlayTimeInfo = nil
            self.player?.pause()
            Log.print("stop previous radio")
        }

        RadioPlayer.curChannelName = channelName
        RadioPlayer.curChannelUrl = channelUrl

        self.enableRemoteCommandCenter(enable: true)

        let playerItem = AVPlayerItem.init(url: channelUrl)
        self.player = AVPlayer.init(playerItem:playerItem)
        self.player?.volume = 1.0
        self.player?.play()
        
        if ( RadioChannelResources.checkLiveChannel(channelName: channelName) ) {
            RadioPlayer.IsRadioPlaying = RadioPlayStatus.live
            RadioPlayer.curPlayTimeInfo = nil
        } else {
            RadioPlayer.IsRadioPlaying = RadioPlayStatus.playing
        }
        
        RadioPlayer.curProgramName = "Program Name"
        RadioPlayer.setAlbumArtPrepare(channelName: channelName, isPlaying: false)
        RadioPlayer.setNowPlayingInfo(channelName: channelName, programName: RadioPlayer.curProgramName, toPlay: true)
        NotificationCenter.default.post(name: .updateAlbumArtMain, object: nil)
    }
    
    static func setAlbumArtPrepare(channelName: String, isPlaying: Bool) {
        Log.print("setAlbumArtPrepare: \(channelName)")
        switch channelName {
        case "KBS Classic FM":
            RadioChannelResources.setKBSAlbumArt(channelCode: 24, isPlaying: isPlaying)
        case "KBS Cool FM":
            RadioChannelResources.setKBSAlbumArt(channelCode: 25, isPlaying: isPlaying)
        case "KBS1 Radio":
            RadioChannelResources.setKBSAlbumArt(channelCode: 21, isPlaying: isPlaying)
        case "KBS Happy FM":
            RadioChannelResources.setKBSAlbumArt(channelCode: 22, isPlaying: isPlaying)
        case "MBC Standard FM":
            RadioChannelResources.setMBCAlbumArt(channelNameKeyword: "표준FM", isPlaying: isPlaying)
        case "MBC FM For U":
            RadioChannelResources.setMBCAlbumArt(channelNameKeyword: "FM4U", isPlaying: isPlaying)
        case "SBS Love FM":
            RadioChannelResources.setSBSAlbumArt(channelNameKeyword: "LOVE FM", isPlaying: isPlaying)
        case "SBS Power FM":
            RadioChannelResources.setSBSAlbumArt(channelNameKeyword: "POWER FM", isPlaying: isPlaying)
        case "CBS Music":
            RadioChannelResources.setCBSAlbumArt()
        case "TBS FM" :
            RadioChannelResources.setTBSAlbumArt(channelName: channelName, isPlaying: isPlaying)
        case "AFN The Eagle" , "AFN The Voice", "AFN Joe Radio", "AFN Legacy":
            RadioChannelResources.setAFNAlbumArt(channelName: channelName)
        case "TEST":
            NotificationCenter.default.post(name: .callTestTimeSettingMain, object: nil)
        default: break
        }
    }
    
    static func setNowPlayingInfo(channelName: String, programName: String, toPlay: Bool)
    {
        Log.print("setNowPlayingInfo channelName(\(channelName)) programName(\(programName))")
        let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

        let artworkData = Data()
        
        if RadioPlayer.curAlbumImg == nil {
            let image = UIImage(data: artworkData) ?? UIImage()
            let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {  (_) -> UIImage in
                return image
            })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        } else {
            let artwork = MPMediaItemArtwork(boundsSize: RadioPlayer.curAlbumImg!.size, requestHandler: {  (_) -> UIImage in
                return RadioPlayer.curAlbumImg!
            })
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        let duration = CloudRadioUtils.getDifftimeSecondWith(startTime: RadioPlayer.curPlayTimeInfo?.starttime, endTime: RadioPlayer.curPlayTimeInfo?.endtime)
        let nowString = CloudRadioUtils.getNowtimeString()
        let elapsed = CloudRadioUtils.getDifftimeSecondWith(startTime: RadioPlayer.curPlayTimeInfo?.starttime, endTime: nowString)
        
        if ( duration != nil && elapsed != nil ) {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            // 콘텐츠 재생 시간에 따른 progressBar 초기화
            if ( toPlay ) {
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
            } else {
                nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0
            }
            // 콘텐츠 현재 재생시간
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        }

        nowPlayingInfo[MPMediaItemPropertyTitle] = programName
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "CloudRadio"
        nowPlayingInfo[MPMediaItemPropertyArtist] = channelName
        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        
        HomeViewController.programName = programName
        HomeViewController.channelName = channelName
    }
    
    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared();
        commandCenter.playCommand.isEnabled = false
        commandCenter.playCommand.addTarget {event in
            Log.print("mediaCenter play")
            self.playRadio(channelName: RadioPlayer.curChannelName, channelUrl: RadioPlayer.curChannelUrl!)
            return .success
        }
        commandCenter.pauseCommand.isEnabled = false
        commandCenter.pauseCommand.addTarget {event in
            Log.print("mediaCenter pause")
            self.pauseRadio()
            return .success
        }
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.nextTrackCommand.addTarget { event in
            Log.print("mediaCenter next")
            NotificationCenter.default.post(name: .skipRadioMain, object: nil)
            return .success
        }
        commandCenter.previousTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.addTarget { event in
            Log.print("mediaCenter previous")
            NotificationCenter.default.post(name: .previousRadioMain, object: nil)
            return .success
        }
    }
    
    func enableRemoteCommandCenter(enable: Bool) {
        Log.print("enableRemoteCommandCenter \(enable)")
        let commandCenter = MPRemoteCommandCenter.shared();
        commandCenter.playCommand.isEnabled = enable
        commandCenter.pauseCommand.isEnabled = enable
        commandCenter.nextTrackCommand.isEnabled = enable
        commandCenter.previousTrackCommand.isEnabled = enable
    }
    
    func enableAudioSessionActive(enable: Bool) {
        do {
            Log.print("enableAudioSessionActive \(enable)")
            try audioSession?.setActive(enable)
        } catch {
            Log.print("Error enableAudioSessionActive: \(error.localizedDescription)")
        }
    }
    
    
    // 2. 처리
    @objc func handleInterruption(notification: Notification) {
        Log.print("handleInterruption called")
        
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                Log.print("ERROR to handle interrupt")
                return
        }

        // Switch over the interruption type.
        switch type {

        case .began:
            // An interruption began. Update the UI as necessary.
            Log.print("interrupt start")
            self.pauseRadio()

        case .ended:
           // An interruption ended. Resume playback, if appropriate.
            Log.print("interrupt end")

            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // An interruption ended. Resume playback.
                Log.print("playback resume")
                self.playRadio(channelName: RadioPlayer.curChannelName, channelUrl: RadioPlayer.curChannelUrl!)

            } else {
                // An interruption ended. Don't resume playback.
                Log.print("playback didn't resume")
            }
        default:
            Log.print("default?")
            break
        }
    }
}

extension RadioPlayer: RadioPlayerDelegate {
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
    
    func startNormalRadio(channelName: String, address: String) {
        Log.print("startNormalRadio: \(channelName)")

        DispatchQueue.global().async {
            guard let url = URL.init(string: address) else {
                Log.print("Error for playing")
                return
            }
            self.playRadio(channelName: channelName, channelUrl: url)
        }
    }
    
    func startKBSRadio(channelName: String, channelCode: Int ) {
        Log.print("startKBSRadio: \(channelName)")
        
        DispatchQueue.global().async {
            guard let address = RadioChannelResources.getKBSFMAddressByChannelCode(channelCode: channelCode) else {
                Log.print("Error for playing: Can't get address")
                return
            }
            guard let url = URL.init(string: address) else {
                Log.print("Error for playing")
                return
            }
            self.playRadio(channelName: channelName, channelUrl: url)
        }
    }
    
    func startTBFMSRadio(channelName: String, channelPLSAddress: String) {
        let mainURL = channelPLSAddress

        DispatchQueue.global().async {
            guard let main = URL(string: mainURL) else {
              Log.print("Error: \(mainURL) doesn't seem to be a valid URL")
              return
            }
            do {
                let lolMain = try String(contentsOf: main, encoding: .utf8)
                if let doc = try? HTML(html: lolMain, encoding: .utf8) {
                    
                    // Search for nodes by XPath
                    for head in doc.xpath("/html/body/div[2]/div/script") {
                        guard let value = head.toHTML else { return }
                        
                        var streamAddr = value[value.endIndex(of: "if (ch == \"CH_A\") streamUrl = ")!..<value.index(of: "else if (ch == \"CH_E\")")!]
                        streamAddr = streamAddr[streamAddr.index(streamAddr.startIndex, offsetBy: 1)..<streamAddr.index(streamAddr.endIndex, offsetBy: -3)]
                        Log.print("streamAddr: \(streamAddr)")
                        guard let url = URL.init(string: String(streamAddr)) else {
                            Log.print("Error for playing")
                            return
                        }
                        self.playRadio(channelName: channelName, channelUrl: url)
                    }
                }
            } catch let error {
                Log.print("Error: \(error)")
            }
        }
    }
    
    func startRadio(channelName: String, channelPLSAddress: String) {
        DispatchQueue.global().async {
            do {
                let dataString = try String(contentsOf: URL(string: channelPLSAddress)!, encoding: .utf8)
                Log.print("[addr: \(channelPLSAddress)] dataString=\(dataString)")
                // if address is over than one
                if ( dataString.contains("File2") ) {
                    let playAddress = String(dataString[dataString.endIndex(of: "File1=")!..<dataString.index(of: "File2")!]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    Log.print("playAddress: (\(playAddress))")
                    guard let url = URL.init(string: playAddress)
                        else {
                            Log.print("Error for playing")
                            return
                    }
                    self.playRadio(channelName: channelName, channelUrl: url)
                }
                else if ( dataString.contains("File1") && dataString.contains("Title1") ) {
                    let playAddress = String(dataString[dataString.endIndex(of: "File1=")!..<dataString.index(of: "Title1")!]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    Log.print("playAddress: (\(playAddress))")
                    guard let url = URL.init(string: playAddress)
                        else {
                            Log.print("Error for playing")
                            return
                    }
                    self.playRadio(channelName: channelName, channelUrl: url)
                } else if ( channelPLSAddress.contains("m3u8") ) {
                    Log.print("m3u8 type!")
                    guard let url = URL.init(string: channelPLSAddress)
                        else {
                            Log.print("Error for playing")
                            return
                    }
                    self.playRadio(channelName: channelName, channelUrl: url)
                }
            } catch let error {
                Log.print("Error: \(error)")
            }
        }
    }
    
    func getPlayingState() -> RadioPlayStatus {
        if ( isPlaying() ) {
            if ( RadioPlayer.IsRadioPlaying == RadioPlayStatus.playing || RadioPlayer.IsRadioPlaying == RadioPlayStatus.paused ) {
                return RadioPlayer.IsRadioPlaying
            } else {
                return RadioPlayStatus.unknown
            }
        } else {
            return RadioPlayStatus.stopped
        }
    }
    
    func isPlaying() -> Bool {       
        if self.player == nil { return false }
        
        if ( self.player?.rate != 0 && self.player?.error == nil ) || RadioPlayer.IsRadioPlaying == RadioPlayStatus.paused {
            return true
        }
        return false
    }
}

                            
extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
