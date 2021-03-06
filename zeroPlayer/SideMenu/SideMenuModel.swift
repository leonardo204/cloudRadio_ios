//
//  MenuModel.swift
//  CustomSideMenuiOSExample
//
//  Created by John Codeos on 2/20/21.
//

import UIKit

enum CHANNELTYPE {
    case RADIO, YOUTUBEPLAYLIST, SAMPLE
}

struct SideMenuModel {
    var type: CHANNELTYPE
    var icon: UIImage
    var title: String
    var playlistId: String
}

class SideMenuDataModel {

    var menu: [SideMenuModel] = [
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "KBS Classic FM", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "MBC FM For U", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "KBS Cool FM", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "SBS Love FM", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "SBS Power FM", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "MBC Standard FM", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "KBS Happy FM", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "KBS1 Radio", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "CBS Music", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "TBS FM", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "AFN The Eagle", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "AFN The Voice", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "AFN Joe Radio", playlistId: "N/A"),
        SideMenuModel(type: .RADIO, icon: UIImage(systemName: "music.note")!, title: "AFN Legacy", playlistId: "N/A")
    ]
    
    // locked ??????????????? ????????? ??????
    var lockedMenu: [SideMenuModel] = [
        SideMenuModel(type: .SAMPLE, icon: UIImage(systemName: "music.note")!, title: "ADD PLAYLIST", playlistId: "N/A")
    ]

    // 1. menu reordering ??? ?????? ????????? ?????? ????????? ??????
    // 2. ?????? ?????? ?????? editing ??? ????????? json ?????? ??????
    // 3. ?????? side menu ?????? ??? json ????????? ?????????, menuMirror ??? ???????????? ??????
    var menuMirror = [SideMenuModel]()

}
