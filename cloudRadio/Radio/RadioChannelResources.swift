//
//  RadioChannelResources.swift
//  cloudRadio
//
//  Created by zerolive on 2021/11/19.
//

import Foundation
import UIKit
import Kanna
import Alamofire
import SwiftyJSON

struct MBCChannelJson: Codable {
    var ServerTime: String
    var TVList: [MBCChannelDetailType]
    var CH24List: [MBCChannelDetailType]
    var RadioList: [MBCChannelDetailType]
}

struct MBCChannelDetailType: Codable {
    var `Type`: String
    var ScheduleCode: String
    var MediaCode: String
    var TypeTitle: String
    var Title: String
    var HomepageURL: String
    var StartTime: String
    var EndTime: String
    var Photo: String
    var percentTime: String
    var IsOnAirNow: String
    var TargetAge: String
    var OrderNum: String
    var OnAirImage: String
}

struct KBSChannelJsonType: Codable {
    var ret: Int
    var msg: String
    var channel_item: [KBSChannelType]
    var cached_datetime: String
    var channelMaster: [KBSChannelMaster]
}

struct KBSChannelType: Codable {
    var streamprotocol: String
    var service_url: String
    var nid: String
    var screentype: String
    var bitrate: String
    var channel_code: String
}

struct KBSChannelMaster: Codable {
    var meta_refresh_sec: Int
    var pps_kind_label: String
    var image_path_channel_logo: String
    var mobile_ad_yn: String
    var nid: String
    var breaking_yn: String
    var channel_group: String
    var image_path_video_thumbnail: String
    var channel_code: String
    var uccm_onair: String
    var pc_ad_yn: String
    var title: String
    var board_name: String
    var chat_type: String
    var pps_kind_value: String
    var chat_refresh_sec: Int
    var channel_type: String
    var sort_order: Int
}

struct SBSChannelJSonType: Codable {
    var props: [SBSChannelProps]
    var page: String
    var query: String
    var buildId: String
    var runtimeConfig: String
    var nextExport: Bool
    var isFallback: Bool
    var gssp: Bool
    var locale: String
    var locales: [String]
    var defaultLocale: String
}

struct SBSChannelProps: Codable {
    var pageProps: [SBSChannelPropType]
    var __N_SSP: Bool
}

struct SBSChannelPropType: Codable {
    var channelname: String
    var channelid: String
    var programid: String
    var smr_programid: String
    var section: String
    var target_age: String
    var homeurl: String
    var type: String
    var onair_yn: String
    var onair_text: String
    var overseas_yn: String
    var overseas_text: String
    var title: String
    var subtitle: String
    var starttime: String
    var endtime: String
    var channel_payment: String
    var mobile_free_channel: String
    var pc_free_channel: String
    var guest_name: String
    //var thumbs: [SBSThumbs] // -> It's not permitted number name variable. Use thumbimg instead of this
    var thumbimg: String
    var background: String
    var program_image: String
}

//struct SBSThumbs: Codable {
//    var "640": String
//}

struct RadioTimeInfo {
    var starttime: String
    var endtime: String
    var interval: Double // endtime - now
}

struct RadioChannelModel {
    var playURL: String
    var address: String
    var name: String
    var channelcode: Int
}

struct CBSMusicProgramTable {
    var starttime: String
    var endtime: String
    var programName: String
    var ImageAddress: String
}

class RadioChannelResources {
        
    static func getKBSFMAddressURL(channelCode: Int) -> String? {
        var url: String? = nil
        
        for i in 0..<CHANNELS.count {
            if ( channelCode == CHANNELS[i].channelcode ) {
                url = CHANNELS[i].playURL
            }
        }
        
        return url
    }

    
    static func getKBSFMAddressByChannelCode(channelCode: Int) -> String? {
        let mainURL = "https://onair.kbs.co.kr/index.html?sname=onair&stype=live&ch_code=" + String(channelCode)
        guard let main = URL(string: mainURL) else {
          Log.print("Error: \(mainURL) doesn't seem to be a valid URL")
          return nil
        }
        
        var addr: String? = nil
        
        do {
            let lolMain = try String(contentsOf: main, encoding: .utf8)
            if let doc = try? HTML(html: lolMain, encoding: .utf8) {
                
                guard let value = doc.body?.toHTML else { return addr }

                let tmp = String(value[value.endIndex(of: "var channel = JSON.parse")!..<value.index(of: "var channelInfoJson")!]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let addrJsonString = String(tmp[tmp.endIndex(of: "('")!..<tmp.index(of: "');")!]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "\\", with: "")
                
                // string to json
                let addrJson = JSON.init(parseJSON: addrJsonString)
                let channelItem = addrJson["channel_item"].arrayValue[0]
                addr = channelItem["service_url"].stringValue
//                Log.print("addr: \(addr)")
            }
        } catch let error {
            Log.print("Error: \(error)")
        }

        return addr
    }
    
    static func setAFNAlbumArt(channelName: String) {
        let addr = "https://www.afnpacific.net/portals/101/Images/AFN360.png"
        let url = URL(string: addr)
        do {
            let data = try Data(contentsOf: url!)
            let image = UIImage(data: data)
            RadioPlayer.curAlbumImg = image
            RadioPlayer.curAlbumUrl = addr
            RadioPlayer.curProgramName = channelName + " OnAir"
        } catch let error {
            Log.print("Error: \(error)")
        }
    }
    
    static func setDefaultAlbumArt(programName: String) {
        let addr = "http://zerolive7.iptime.org:9093/api/public/dl/M7zKvA4J/01_project/cloudradio/fb2637b9-eeaa-4170-adb0-ee51fa095fd2.jpg"
        let url = URL(string: addr)
        do {
            let data = try Data(contentsOf: url!)
            let image = UIImage(data: data)
            RadioPlayer.curAlbumImg = image
            RadioPlayer.curAlbumUrl = addr
            RadioPlayer.curProgramName = programName + " OnAir"
        } catch let error {
            Log.print("Error: \(error)")
        }
    }
    
    static func setCBSAlbumArt() {
        
        for i in 0..<CBSMUSIC.count {
            guard let elapsed = CloudRadioUtils.getElapsedWithMin(startTime: CBSMUSIC[i].endtime) else { continue }
            Log.print("endtime: \(CBSMUSIC[i].endtime) . elapsed: \(elapsed)")
            if elapsed < 0.0 || elapsed == 80460 /* In case of 24:00 */ {
                let addr = CBSMUSIC[i].ImageAddress
                let url = URL(string: addr)
                do {
                    let data = try Data(contentsOf: url!)
                    let image = UIImage(data: data)
                    RadioPlayer.curAlbumImg = image
                    RadioPlayer.curAlbumUrl = addr
                    RadioPlayer.curProgramName = CBSMUSIC[i].programName
                    
                    Log.print("start(\(CBSMUSIC[i].starttime)) ~ end(\(CBSMUSIC[i].endtime))")
                    let radioTimeInfo = RadioTimeInfo(starttime: String(CBSMUSIC[i].starttime), endtime: String(CBSMUSIC[i].endtime), interval: CloudRadioUtils.getDifftimeSecondForEndtime(endTime: String(CBSMUSIC[i].endtime)))
                    RadioPlayer.curPlayTimeInfo = radioTimeInfo
                    NotificationCenter.default.post(name: .startRadioTimerMain, object: radioTimeInfo)
                    break
                } catch let error {
                    Log.print("Error: \(error)")
                    break
                }
            }
        }
    }
    
    static func setTBSAlbumArt(channelName: String, isPlaying: Bool) {
        let mainURL = getAddressByName(channelName: channelName)

        guard let main = URL(string: mainURL!) else {
            Log.print("Error: \(String(describing: mainURL)) doesn't seem to be a valid URL")
            return
        }
        do {
            let lolMain = try String(contentsOf: main, encoding: .utf8)
            if let doc = try? HTML(html: lolMain, encoding: .utf8) {
                
                // search for time info
                guard let bodyValue = doc.body?.toHTML else { return }
                let time1 = bodyValue[bodyValue.endIndex(of: "<span class=\"time\">")!..<bodyValue.index(of: "<span class=\"tit\">")!]
                let starttime = time1[time1.startIndex..<time1.index(time1.startIndex, offsetBy: 5)]
                var endtime = time1[time1.index(time1.startIndex, offsetBy: 8)..<time1.index(time1.startIndex, offsetBy: 13)]
                
                if ( endtime == "00:00" ) {
                    endtime = "24:00"
                }
                
                Log.print("start(\(starttime)) ~ end(\(endtime))")
                let radioTimeInfo = RadioTimeInfo(starttime: String(starttime), endtime: String(endtime), interval: CloudRadioUtils.getDifftimeSecondForEndtime(endTime: String(endtime)))
                RadioPlayer.curPlayTimeInfo = radioTimeInfo
                
                // search for channel name
                let channelName1 = bodyValue[bodyValue.endIndex(of: "<span class=\"tit\">")!..<bodyValue.endIndex]
                let channelName2 = channelName1[channelName1.startIndex..<channelName1.index(of: "</span>")!]
                print("channeName: (\(channelName2))")
                RadioPlayer.curProgramName = String(channelName2)
                
                // Search for image
                for head in doc.xpath("/html/body/div[2]/div/script") {
                    guard let value = head.toHTML else { return }
                    
                    var imgAddr = value[value.endIndex(of: "posterUrl =")!..<value.index(of: "player = new noplayer")!]
                    imgAddr = imgAddr[imgAddr.index(imgAddr.startIndex, offsetBy: 2)..<imgAddr.index(imgAddr.endIndex, offsetBy: -4)]
                    Log.print("imgAddr: \(imgAddr)")

                    let url = URL(string: String(imgAddr))
                    let data = try Data(contentsOf: url!)
                    let image = UIImage(data: data)
                    RadioPlayer.curAlbumImg = image
                    RadioPlayer.curAlbumUrl = String(imgAddr)
                }
            }
        } catch let error {
            Log.print("Error: \(error)")
        }
    }
    
    // 0: powerFM, 1: loveFM
    static func setSBSAlbumArt(channelNameKeyword: String, isPlaying: Bool) {
        let address = "https://www.sbs.co.kr/" + RadioChannelResources.SBSLangType + "/live?div=gnb_pc"
        let url = URL(string: address)
        do {
            let lolMain = try String(contentsOf: url!, encoding: .utf8)
            if let doc = try? HTML(html: lolMain, encoding: .utf8) {
                
                // Search for nodes by XPath
                guard let value = doc.body?.toHTML else { return }

                print(value)
                
                var jsonString: String = ""
                Log.print("sbs check base: \(value.contains("<script id=\"__NEXT_DATA__\" type=\"application/json\">")) ")
                Log.print("sbs check 1: \(value.contains("</script><script nomodule=")) ")
                Log.print("sbs check 2: \(value.contains("scriptLoader")) ")
                if ( value.contains("</script><script nomodule=")) {
                    Log.print("sbs case 1")
                    jsonString = String(value[value.endIndex(of: "<script id=\"__NEXT_DATA__\" type=\"application/json\">")!..<value.index(of: "</script><script nomodule=")!]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                } else if ( value.contains("scriptLoader") ) {
                    Log.print("sbs case 2")
                    let guessEndJsonIdx = value.index(value.index(of: "scriptLoader")!, offsetBy: 17)
                    jsonString = String(value[value.endIndex(of: "<script id=\"__NEXT_DATA__\" type=\"application/json\">")!..<guessEndJsonIdx]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                } else {
                    Log.print("parse error. no matched keywords for programs")
                    setDefaultAlbumArt(programName: channelNameKeyword)
                    return
                }
//                Log.print("json: \(jsonString)")
                                
                // string to json
                let json = JSON.init(parseJSON: jsonString)
                let arrayLength = json["props"]["pageProps"]["radio"].count
                Log.print("radio length: \(arrayLength) ")
                
                if ( arrayLength == 0 ) {
                    Log.print("parse error. arrayLength is 0")
                    setDefaultAlbumArt(programName: channelNameKeyword)
                    return
                }

                for i in 0...arrayLength {
                    let radioList1 = json["props"]["pageProps"]["radio"].arrayValue[i]
                    let channelname = radioList1["channelname"].stringValue
                    Log.print("radio channelname: \(channelname) ")

                    if channelname == channelNameKeyword {
                        let photo1 = radioList1["thumbimg"].stringValue
                        let title = radioList1["title"].stringValue
                        var endtime = radioList1["endtime"].stringValue
                        let starttime = radioList1["starttime"].stringValue
                        
                        if ( endtime == "00:00" ) {
                            endtime = String("24:00")
                        }
                        
                        Log.print("title: \(title)   startTime(\(starttime)) - endTime(\(endtime))")
                        let radioTimeInfo = RadioTimeInfo(starttime: starttime, endtime: endtime, interval: CloudRadioUtils.getDifftimeSecondForEndtime(endTime: endtime))
                        RadioPlayer.curPlayTimeInfo = radioTimeInfo
                        
//                        if ( isPlaying == false ) {
                            NotificationCenter.default.post(name: .startRadioTimerMain, object: radioTimeInfo)
//                        }
                        
                        let url = URL(string: photo1)
                        let data = try Data(contentsOf: url!)
                        let image = UIImage(data: data)
                        RadioPlayer.curAlbumImg = image
                        RadioPlayer.curAlbumUrl = photo1
                        RadioPlayer.curProgramName = title
                        
                        break
                    }
                }
            }
        } catch let error {
            Log.print("Error: \(error)")
        }
    }
    
    static func setMBCAlbumArt(channelNameKeyword: String, isPlaying: Bool) {
        let url = URL(string: "https://control.imbc.com/Schedule/PCONAIR?type=radio")
        do {
            let lolMain = try String(contentsOf: url!, encoding: .utf8)
            if let doc = try? HTML(html: lolMain, encoding: .utf8) {
                
                // Search for nodes by XPath
                guard let value = doc.body?.toHTML else { return }
                
                let jsonString = String(value[value.endIndex(of: "<body><p>")!..<value.index(of: "</p></body>")!]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
//                Log.print(jsonString)
                
                // string to json
                let json = JSON.init(parseJSON: jsonString)
                let arrayLength = json["RadioList"].count
                Log.print("radio length: \(arrayLength) ")

                for i in 0...arrayLength {
                    let radioList1 = json["RadioList"].arrayValue[i]
                    let TypeTitle = radioList1["TypeTitle"].stringValue
                    Log.print("radio channelname: \(TypeTitle) ")

                    if channelNameKeyword == TypeTitle {
                        let photo1 = radioList1["Photo"].stringValue
                        let title = radioList1["Title"].stringValue
                        var starttime = radioList1["StartTime"].stringValue
                        var endtime = radioList1["EndTime"].stringValue
                        let sepIdx = endtime.index(endtime.startIndex, offsetBy: 2)
                        starttime.insert(":", at: sepIdx)
                        endtime.insert(":", at: sepIdx)
                        
                        if ( endtime == "00:00" ) {
                            endtime = String("24:00")
                        }
                        
                        Log.print("title: \(title)   startTime(\(starttime)) - endTime(\(endtime))")
                        
                        let radioTimeInfo = RadioTimeInfo(starttime: starttime, endtime: endtime, interval: CloudRadioUtils.getDifftimeSecondForEndtime(endTime: endtime))
                        RadioPlayer.curPlayTimeInfo = radioTimeInfo
                        
//                        if ( isPlaying == false ) {
                            NotificationCenter.default.post(name: .startRadioTimerMain, object: radioTimeInfo)
//                        }
                        
                        let url = URL(string: photo1)
                        let data = try Data(contentsOf: url!)
                        let image = UIImage(data: data)
                        RadioPlayer.curAlbumImg = image
                        RadioPlayer.curAlbumUrl = photo1
                        RadioPlayer.curProgramName = title
                        
                        break
                    }
                }
                

            }
        } catch let error {
            Log.print("Error: \(error)")
        }
    }
    
    static func setKBSAlbumArt(channelCode: Int, isPlaying: Bool) {
        let mainURL = "https://onair.kbs.co.kr/index.html?sname=onair&stype=live&ch_code=" + String(channelCode) + "&ch_type=radioList"

        guard let main = URL(string: mainURL) else {
          Log.print("Error: \(mainURL) doesn't seem to be a valid URL")
          return
        }
        do {
            let lolMain = try String(contentsOf: main, encoding: .utf8)
            if let doc = try? HTML(html: lolMain, encoding: .utf8) {
                
                // Search for nodes by XPath
                for head in doc.xpath("//meta[@property=\"og:image\"]") {
                    guard let value = head.toHTML else { return }
                    Log.print("parse: \(value)")
                    let imgAddress = String(value[value.endIndex(of: "content=\"")!..<value.index(of: "\">")!]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    Log.print("imgAddress: \(imgAddress)")
                    let url = URL(string: imgAddress)
                    let data = try Data(contentsOf: url!)
                    let image = UIImage(data: data)
                    RadioPlayer.curAlbumImg = image
                    RadioPlayer.curAlbumUrl = imgAddress
                }
                
                for head in doc.xpath("//meta[@property=\"og:description\"]") {
                    guard let value = head.toHTML else { return }
                    Log.print("parse: \(value)")
                    let title1 = String(value[value.endIndex(of: "content=\"")!..<value.index(of: "\">")!]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    let startIndex = title1.index(title1.startIndex, offsetBy: 4)
                    let lastIndex = title1.index(title1.endIndex, offsetBy: -12)
                    let title = title1[startIndex..<lastIndex].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    Log.print("title1: \(title1)")
                    RadioPlayer.curProgramName = title

                    // 11:00~12:00
                    // timeLastIndex: 11:00~(1)2:00
                    // timeFirstIndex: (1)1:00~12:00
                    // timeSepIndex: 11:00(~)12:00
                    let timeLastIndex = title1.index(title1.endIndex, offsetBy: -5)
                    let timeSepIndex = title1.index(title1.endIndex, offsetBy: -6)
                    let timeFirstIndex = title1.index(title1.endIndex, offsetBy: -11)

                    let starttime = title1[timeFirstIndex..<timeSepIndex].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    var endtime = title1[timeLastIndex..<title1.endIndex].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                    if ( endtime == "00:00" ) {
                        endtime = String("24:00")
                    }
                
                    let interval = CloudRadioUtils.getDifftimeSecondForEndtime(endTime: endtime)
                    Log.print("title: \(title)   startTime(\(starttime)) - endTime(\(endtime))  => interval: \(interval)")
                    let radioTimeInfo = RadioTimeInfo(starttime: starttime, endtime: endtime, interval: interval)
                    RadioPlayer.curPlayTimeInfo = radioTimeInfo
                    
//                    if ( isPlaying == false ) {
                        NotificationCenter.default.post(name: .startRadioTimerMain, object: radioTimeInfo)
//                    }
                }
            }
        } catch let error {
            Log.print("Error: \(error)")
        }
    }
    
    // KBS channel code 1라디오:21, 2라디오:22, 3라디오:23, 1FM:24, 2FM:25, 한민족:I26, 월드:I92
    static func getChannel(title: String) -> PlayInfo? {
        var info: PlayInfo?
        
        for i in 0..<CHANNELS.count {
            if ( CHANNELS[i].name == title ) {
                info = PlayInfo(channelName: CHANNELS[i].name, channelPLSAddress: CHANNELS[i].address, channelCode: CHANNELS[i].channelcode)
                break
            }
        }
        return info
    }
    
    static func checkLiveChannel(channelName: String) -> Bool {
        var isLive: Bool = false
        switch(channelName) {
        case "AFN The Eagle", "AFN The Voice", "AFN Joe Radio", "AFN Legacy":
            isLive = true
        default: break
        }
        return isLive
    }
    
    static func getAddressByName(channelName: String) -> String? {
        var address: String? = nil
        for i in 0..<CHANNELS.count {
//            Log.print("[\(i)/\(CHANNELS.count)] in(\(channelName)) - compare(\(CHANNELS[i].name))")
            if ( CHANNELS[i].name == channelName ) {
                address = CHANNELS[i].address
                break
            }
        }
        return address
    }
    
    static func getChannelcodeByName(channelName: String) -> Int {
        var channelcode: Int = 0
        for i in 0..<CHANNELS.count {
            if ( CHANNELS[i].name == channelName ) {
                channelcode = CHANNELS[i].channelcode
                break
            }
        }
        return channelcode
    }
    
    static func getIndexByName(channelName: String) -> Int {
        var index: Int = 0
        for i in 0..<CHANNELS.count {
            if ( CHANNELS[i].name == channelName ) {
                index = i
                break
            }
        }
        return index
    }
    
    static var SBSLangType: String = "ko"
    static func changeSBSLangType()  {
        if ( SBSLangType == "ko" ) {
            SBSLangType = "en"
        } else {
            SBSLangType = "ko"
        }
        Log.print("changeSBSLangType: \(RadioChannelResources.SBSLangType)")
    }
    
    static var CHANNELS: [RadioChannelModel] = [
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/kbsfm.pls", name: "KBS Classic FM", channelcode: 24),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/mbcfm.pls", name: "MBC FM For U", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/kbs2fm.pls", name: "KBS Cool FM", channelcode: 25),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/sbs2fm.pls", name: "SBS Love FM", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/sbsfm.pls", name: "SBS Power FM", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/mbcsfm.pls", name: "MBC Standard FM", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/kbs2radio.pls", name: "KBS Happy FM", channelcode: 22),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/kbs1radio.pls", name: "KBS1 Radio", channelcode: 21),
        RadioChannelModel(playURL: "", address: "http://aac.cbs.co.kr/cbs939/_definst_/cbs939.stream/playlist.m3u8", name: "CBS Music", channelcode: 0),
        RadioChannelModel(playURL: "", address: "https://tbs.seoul.kr/player/live.do?channelCode=CH_A", name: "TBS FM", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://playerservices.streamtheworld.com/pls/AFNP_OSN.pls", name: "AFN The Eagle", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://playerservices.streamtheworld.com/pls/AFN_VCE.pls", name: "AFN The Voice", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://playerservices.streamtheworld.com/pls/AFN_JOEP.pls", name: "AFN Joe Radio", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://playerservices.streamtheworld.com/pls/AFN_LGYP.pls", name: "AFN Legacy", channelcode: 0)
    ]
    
    static var CBSMUSIC: [CBSMusicProgramTable] = [
        CBSMusicProgramTable(starttime: "00:00", endtime: "02:00", programName: "시작하는 밤 박준입니다", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/WXAHL8Qo/01_project/cloudradio/CBSMusic_Images/0000_0200.jpg"),
        CBSMusicProgramTable(starttime: "02:00", endtime: "04:00", programName: "이지민의 All that Jazz", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/1salVdVQ/01_project/cloudradio/CBSMusic_Images/0200_0400.jpg"),
        CBSMusicProgramTable(starttime: "04:00", endtime: "06:00", programName: "김윤주의 내가 매일 기쁘게", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/wxtTPr0J/01_project/cloudradio/CBSMusic_Images/0400_0600.jpg"),
        CBSMusicProgramTable(starttime: "06:00", endtime: "07:00", programName: "정민아의 Amazing grace", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/YDeKg4pC/01_project/cloudradio/CBSMusic_Images/0600_0700.jpg"),
        CBSMusicProgramTable(starttime: "07:00", endtime: "09:00", programName: "김용신의 그대와 여는 아침", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/Y9zz-Rx0/01_project/cloudradio/CBSMusic_Images/0700_0900.gif"),
        CBSMusicProgramTable(starttime: "09:00", endtime: "11:00", programName: "강석우의 아름다운 당신에게", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/6sl0QYZZ/01_project/cloudradio/CBSMusic_Images/0900_1100.jpg"),
        CBSMusicProgramTable(starttime: "11:00", endtime: "12:00", programName: "신지혜의 영화음악", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/h3JcS460/01_project/cloudradio/CBSMusic_Images/1100_1200.jpg"),
        CBSMusicProgramTable(starttime: "12:00", endtime: "14:00", programName: "이수영의 12시에 만납시다", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/4Vig49E3/01_project/cloudradio/CBSMusic_Images/1200_1400.jpg"),
        CBSMusicProgramTable(starttime: "14:00", endtime: "16:00", programName: "한동준의 FM POPS", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/4_OotC_9/01_project/cloudradio/CBSMusic_Images/1400_1600.jpg"),
        CBSMusicProgramTable(starttime: "16:00", endtime: "18:00", programName: "박승화의 가요속으로", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/h3DI0b90/01_project/cloudradio/CBSMusic_Images/1600_1800.jpg"),
        CBSMusicProgramTable(starttime: "18:00", endtime: "20:00", programName: "배미향의 저녁스케치", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/IefmAi-M/01_project/cloudradio/CBSMusic_Images/1800_2000.jpeg"),
        CBSMusicProgramTable(starttime: "20:00", endtime: "22:00", programName: "김현주의 행복한 동행", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/gV9CrC0w/01_project/cloudradio/CBSMusic_Images/2000_2200.jpg"),
        CBSMusicProgramTable(starttime: "22:00", endtime: "24:00", programName: "허윤희의 꿈과 음악사이에", ImageAddress: "http://zerolive7.iptime.org:9093/api/public/dl/-_-QlO4o/01_project/cloudradio/CBSMusic_Images/2200_2400.jpg")
    ]
}
