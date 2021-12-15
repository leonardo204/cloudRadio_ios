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

        let dd =  dateFMT.date(from: self)
        return dd
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
        var givenDateDouble: Double = 0.0
        if ( endTime == "24:00" ) {
            givenDateDouble = "23:59".tad2Date()!.timeIntervalSince1970 + (60*1000)
        } else {
            givenDateDouble = endTime.tad2Date()!.timeIntervalSince1970
        }
        
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm"
        let now = Date()
        let nowString = dateFMT.string(from: now)

        let nowDate = nowString.tad2Date()!
        
        Log.print("getDifftimeSecond() now(\(nowString): \(nowDate.timeIntervalSince1970) - endTime(\(endTime): \(givenDateDouble))")
        
        return (givenDateDouble - nowDate.timeIntervalSince1970)
    }
    
    // get interval from "xx:ss"
    // endTime="17:00"
    static func getDifftimeSecondWith(startTime: String?, endTime: String?) -> Double? {
        if ( startTime == nil || endTime == nil ) {
            return nil
        }
        
        var startDateDouble: Double = 0.0
        if ( startTime == "24:00" || startTime == "24:00:00" ) {
            startDateDouble = "00:00".tad2Date()!.timeIntervalSince1970
        } else {
            startDateDouble = startTime!.tad2Date()!.timeIntervalSince1970
        }
        
//        let startDate = startTime!.tad2Date()!
        var givenDateDouble: Double = 0.0
        if ( endTime == "24:00" ) {
            givenDateDouble = "23:59".tad2Date()!.timeIntervalSince1970 + (60*1000)
        } else {
            givenDateDouble = endTime!.tad2Date()!.timeIntervalSince1970
        }
        return (givenDateDouble - startDateDouble)
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
//        let startDate = dateFMT.date(from: startTime!)!
        var startDateDouble: Double = 0.0
        if ( startTime == "24:00" || startTime == "24:00:00" ) {
            startDateDouble = dateFMT.date(from: "00:00:00")!.timeIntervalSince1970
        } else {
            startDateDouble = dateFMT.date(from: startTime!)!.timeIntervalSince1970
        }
        
        return (nowDate.timeIntervalSince1970 - startDateDouble)
    }
    
    static func getElapsedWithMin(startTime: String?) -> Double? {
        if ( startTime == nil ) {
            return nil
        }
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm"
        let now = Date()
        let nowString = dateFMT.string(from: now)
        let nowDate = dateFMT.date(from: nowString)!
//        let startDate = dateFMT.date(from: startTime!)!
        var startDateDouble: Double = 0.0
        if ( startTime == "24:00" || startTime == "24:00:00" ) {
            startDateDouble = dateFMT.date(from: "00:00")!.timeIntervalSince1970
        } else {
            startDateDouble = dateFMT.date(from: startTime!)!.timeIntervalSince1970
        }
        
        return (nowDate.timeIntervalSince1970 - startDateDouble)
    }
    
    static func getDuration(startTime: String?, endTime: String?) -> Double? {
        if ( startTime == nil || endTime == nil ) {
            return nil
        }
        let dateFMT = DateFormatter()
        dateFMT.locale = Locale(identifier:"ko_KR")
        dateFMT.timeZone = TimeZone(abbreviation: "KST")
        dateFMT.dateFormat = "HH:mm:ss"
        
        var startDateDouble: Double = 0.0
        if ( startTime == "24:00" || startTime == "24:00:00" ) {
            startDateDouble = dateFMT.date(from: "00:00:00")!.timeIntervalSince1970
        } else {
            startDateDouble = dateFMT.date(from: startTime!)!.timeIntervalSince1970
        }
        
//        let startDate = dateFMT.date(from: startTime!)!
        
        var givenDateDouble: Double = 0.0
        if ( endTime == "24:00" || endTime == "24:00:00" ) {
            givenDateDouble = dateFMT.date(from: "23:59:00")!.timeIntervalSince1970 + (60*1000)
        } else {
            givenDateDouble = dateFMT.date(from: endTime!)!.timeIntervalSince1970
        }
//        let endDate = dateFMT.date(from: endTime!)!
        
        return (givenDateDouble - startDateDouble)
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
