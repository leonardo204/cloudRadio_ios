//
//  CloudRadioShareValues.swift
//  cloudRadio
//
//  Created by zerolive on 2021/12/07.
//

import Foundation

class CloudRadioShareValues {
    // RADIO TIMER
    static var stopRadioTimerTime = 0.0
    static var stopRadioSwitchisOn = false
    static var stopRadioTimerisActive = false
    static var stopRadioTimer: Timer? = nil
    static var drawRadioTimeTimer: Timer? = nil
    static var globalStopRadioTimer: Timer? = nil
    
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
