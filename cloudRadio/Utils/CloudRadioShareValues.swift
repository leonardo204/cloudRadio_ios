//
//  CloudRadioShareValues.swift
//  cloudRadio
//
//  Created by zerolive on 2021/12/07.
//

import Foundation
import UIKit

class CloudRadioShareValues {
    // Version
    static var versionString = "v1.4"
    
    // hidden count
    static var isUnlocked = false
    static var hiddenCount = 0

    // RADIO TIMER
    static var stopRadioTimerTime = 0.0
    static var stopRadioSwitchisOn = false
    static var stopRadioTimerisActive = false
    static var stopRadioTimer: Timer? = nil
    static var drawRadioTimeTimer: Timer? = nil
    static var globalStopRadioTimer: Timer? = nil
    static var TimeLabel: UILabel? = nil
    static var TimeSlider: UISlider? = nil
    
    // Playlist setting
    static var isShuffle = true
    static var isRepeat = true
    
    static func requestStopRadioTimer() {
        if ( CloudRadioShareValues.stopRadioTimer?.isValid ) != nil {
            Log.print("stop stopRadioTimer")
            CloudRadioShareValues.stopRadioTimer?.invalidate()
            CloudRadioShareValues.stopRadioTimer = nil
        }
        if ( CloudRadioShareValues.drawRadioTimeTimer?.isValid ) != nil {
            Log.print("stop drawRadioTimeTimer")
            CloudRadioShareValues.drawRadioTimeTimer?.invalidate()
            CloudRadioShareValues.drawRadioTimeTimer = nil
        }
    }
}

struct CRSettings: Codable {
    let isUnlocked: Bool
    let isShuffle: Bool
    let isRepeat: Bool
}

struct CRChannels: Codable {
    let channels: [CRChannelInfo]
}

struct CRChannelInfo: Codable {
    let type: Int // 0: radio, 1: youtube playlist
    let title: String
    let playlistId: String
}
