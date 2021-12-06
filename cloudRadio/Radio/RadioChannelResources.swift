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
                let endtime = time1[time1.index(time1.startIndex, offsetBy: 8)..<time1.index(time1.startIndex, offsetBy: 13)]
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
        let url = URL(string: "https://www.sbs.co.kr/ko/live?div=gnb_pc")
        do {
            let lolMain = try String(contentsOf: url!, encoding: .utf8)
            if let doc = try? HTML(html: lolMain, encoding: .utf8) {
                
                // Search for nodes by XPath
                guard let value = doc.body?.toHTML else { return }
                
                let jsonString = String(value[value.endIndex(of: "<script id=\"__NEXT_DATA__\" type=\"application/json\">")!..<value.index(of: "</script><script nomodule=")!]).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
//                Log.print(jsonString)
                                
                // string to json
                let json = JSON.init(parseJSON: jsonString)
                let arrayLength = json["props"]["pageProps"]["radio"].count
                Log.print("radio length: \(arrayLength) ")

                for i in 0...arrayLength {
                    let radioList1 = json["props"]["pageProps"]["radio"].arrayValue[i]
                    let channelname = radioList1["channelname"].stringValue
                    Log.print("radio channelname: \(channelname) ")

                    if channelname == channelNameKeyword {
                        let photo1 = radioList1["thumbimg"].stringValue
                        let title = radioList1["title"].stringValue
                        let endtime = radioList1["endtime"].stringValue
                        let starttime = radioList1["starttime"].stringValue
                        
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
                    let endtime = title1[timeLastIndex..<title1.endIndex].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                
                    Log.print("title: \(title)   startTime(\(starttime)) - endTime(\(endtime))")
                    let radioTimeInfo = RadioTimeInfo(starttime: starttime, endtime: endtime, interval: CloudRadioUtils.getDifftimeSecondForEndtime(endTime: endtime))
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
        case "CBS Music", "AFN The Eagle", "AFN The Voice", "AFN Joe Radio", "AFN Legacy":
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
    
    static var CHANNELS: [RadioChannelModel] = [
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/kbsfm.pls", name: "KBS Classic FM", channelcode: 24),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/mbcfm.pls", name: "MBC FM For U", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/kbs2fm.pls", name: "KBS Cool FM", channelcode: 25),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/sbs2fm.pls", name: "SBS Love FM", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/sbsfm.pls", name: "SBS Power FM", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/mbcsfm.pls", name: "MBC Standard FM", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/kbs2radio.pls", name: "KBS Happy FM", channelcode: 22),
        RadioChannelModel(playURL: "", address: "http://serpent0.duckdns.org:8088/kbs1radio.pls", name: "KBS1 Radio", channelcode: 21),
        RadioChannelModel(playURL: "", address: "https://korradio.stream/cbs.pls", name: "CBS Music", channelcode: 0),
        RadioChannelModel(playURL: "", address: "https://tbs.seoul.kr/player/live.do?channelCode=CH_A", name: "TBS FM", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://playerservices.streamtheworld.com/pls/AFNP_OSN.pls", name: "AFN The Eagle", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://playerservices.streamtheworld.com/pls/AFN_VCE.pls", name: "AFN The Voice", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://playerservices.streamtheworld.com/pls/AFN_JOEP.pls", name: "AFN Joe Radio", channelcode: 0),
        RadioChannelModel(playURL: "", address: "http://playerservices.streamtheworld.com/pls/AFN_LGYP.pls", name: "AFN Legacy", channelcode: 0)
    ]
}
