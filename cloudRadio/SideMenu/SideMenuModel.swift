//
//  MenuModel.swift
//  CustomSideMenuiOSExample
//
//  Created by John Codeos on 2/20/21.
//

import UIKit

enum CHANNELTYPE {
    case RADIO, YOUTUBEPLAYLIST
}

struct SideMenuModel {
    var type: CHANNELTYPE
    var icon: UIImage
    var title: String
}
