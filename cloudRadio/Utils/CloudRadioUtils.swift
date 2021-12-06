//
//  CloudRadioUtils.swift
//  cloudRadio
//
//  Created by zerolive on 2021/11/24.
//

import Foundation

extension String {
    static func timestamp() -> String {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm"
        let now = Date()

        return String(format: "%@", dateFMT.string(from: now))
    }
    
    static func timestampSec() -> String {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm:ss"
        let now = Date()

        return String(format: "%@", dateFMT.string(from: now))
    }

    func tad2Date() -> Date? {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm"

        return dateFMT.date(from: self)
    }
    
    func tad2DateSec() -> Date? {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm:ss"

        return dateFMT.date(from: self)
    }
}

class CloudRadioUtils {
    static func currentTimeInMilliSeconds()-> Int {
        let currentDate = Date()
        let since1970 = currentDate.timeIntervalSince1970
        return Int(since1970 * 1000)
    }
    
    // get interval from "xx:ss"
    // endTime="17:00"
    static func getDifftimeSecondForEndtime(endTime: String) -> Double {
        let givenDate = endTime.tad2Date()!
        
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm"
        let now = Date()
        let nowString = dateFMT.string(from: now)

        let nowDate = nowString.tad2Date()!
        
        Log.print("getDifftimeSecond() now(\(nowString)) - endTime(\(endTime))")
        
        return (givenDate.timeIntervalSince1970 - nowDate.timeIntervalSince1970)
    }
    
    // get interval from "xx:ss"
    // endTime="17:00"
    static func getDifftimeSecondWith(startTime: String?, endTime: String?) -> Double? {
        if ( startTime == nil || endTime == nil ) {
            return nil
        }
        let startDate = startTime!.tad2Date()!
        let endDate = endTime!.tad2Date()!
        return (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
    }
    
    static func getElapsedWith(startTime: String?) -> Double? {
        if ( startTime == nil ) {
            return nil
        }
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm:ss"
        let now = Date()
        let nowString = dateFMT.string(from: now)
        let nowDate = dateFMT.date(from: nowString)!
        let startDate = dateFMT.date(from: startTime!)!
        
        return (nowDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
    }
    
    static func getDuration(startTime: String?, endTime: String?) -> Double? {
        if ( startTime == nil || endTime == nil ) {
            return nil
        }
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm:ss"
        let startDate = dateFMT.date(from: startTime!)!
        let endDate = dateFMT.date(from: endTime!)!
        
        return (endDate.timeIntervalSince1970 - startDate.timeIntervalSince1970)
    }
    
    static func getRemains(endtime: String?) -> Double? {
        if ( endtime == nil ) {
            return nil
        }
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm:ss"
        let endDate = dateFMT.date(from: endtime!)!
        let nowString = getNowtimeStringSeconds()
        let nowDate = dateFMT.date(from: nowString)!
        return (endDate.timeIntervalSince1970 - nowDate.timeIntervalSince1970)
    }
    
    static func getNowtimeString() -> String {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm"
        let now = Date()
        let nowString = dateFMT.string(from: now)
        
        return nowString
    }
    
    static func getNowtimeStringSeconds() -> String {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm:ss"
        let now = Date()
        let nowString = dateFMT.string(from: now)
        
        return nowString
    }
    
    static func getDifftimeString(diffSecond: Double) -> String {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm"
        return dateFMT.string(from: NSDate(timeIntervalSince1970: (getNowtimeString().tad2Date()!.timeIntervalSince1970 + diffSecond)) as Date )
    }
    
    static func getDateValue(timeString: String?) -> Double? {
        if ( timeString == nil ) { return nil }
        return timeString?.tad2DateSec()?.timeIntervalSince1970
    }
    
    static func getDateString(timevalue: Double) -> String {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm:ss"
        let targetDate = dateFMT.string(from: NSDate(timeIntervalSince1970: timevalue) as Date )
        return targetDate
    }
    
    static func getUTCDateString(timevalue: Double) -> String {
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "UTC")
        dateFMT.dateFormat = "HH:mm:ss"
        let targetDate = dateFMT.string(from: NSDate(timeIntervalSince1970: timevalue) as Date )
        return targetDate
    }
    
    // get 0.00 ~ 1.00
    static func getPercentProgress(elapsed: Double, duration: Double) -> Float {
//        Log.print("elapsed: \(elapsed) - duration: \(duration)")
        let percent = Float(round((elapsed/duration)*1000)/1000)
        return percent
    }
}
