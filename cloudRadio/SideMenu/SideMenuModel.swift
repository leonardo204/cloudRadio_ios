//
//  MenuModel.swift
//  CustomSideMenuiOSExample
//
//  Created by John Codeos on 2/20/21.
//

import UIKit

enum CHANNELTYPE {
    case NONE, RADIO, YOUTUBEPLAYLIST, SAMPLE
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
    
    // locked 상태에서는 메뉴가 없다
    var lockedMenu: [SideMenuModel] = [
        SideMenuModel(type: .SAMPLE, icon: UIImage(systemName: "music.note")!, title: "ADD PLAYLIST", playlistId: "N/A")
    ]

    // 1. menu reordering 에 의해 순서가 바뀐 상태를 저장
    // 2. 순서 바뀐 채로 editing 이 끝나면 json 으로 저장
    // 3. 다음 side menu 구성 시 json 파일이 있다면, menuMirror 에 올려두고 사용
    var menuMirror = [SideMenuModel]()

}
