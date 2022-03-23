//
//  ProgramInfoCell.swift
//  cloudRadio
//
//  Created by zerolive on 2021/12/13.
//

import UIKit

extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        guard let attrString = label.attributedText else {
            return false
        }

        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: attrString)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

class ProgramInfoCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var body: UILabel!
    
    class var identifier: String { return String(describing: self) }
    class var nib: UINib { return UINib(nibName: identifier, bundle: nil) }
    
    var sideMenuData = SideMenuDataModel()
    
    override func awakeFromNib() {
        super.awakeFromNib()

        // Initialization code
        self.body.isUserInteractionEnabled = true
        self.body.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapOnLabel(_:))))
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @objc func handleTapOnLabel(_ recognizer: UITapGestureRecognizer) {
        guard let text = body.attributedText?.string else {
            return
        }
        
        if let range = text.range(of: NSLocalizedString("zerolive7@gmail.com", comment: "zerolive7@gmail.com")),
            recognizer.didTapAttributedTextInLabel(label: body, inRange: NSRange(range, in: text)) {
            goToContactToByEmail(address: text)
        } else if let range = text.range(of: NSLocalizedString(CloudRadioShareValues.versionString, comment: CloudRadioShareValues.versionString)),
                  recognizer.didTapAttributedTextInLabel(label: body, inRange: NSRange(range, in: text)) {
            if ( !CloudRadioShareValues.IsUnlockedFeature ) {
                CloudRadioShareValues.hiddenCount+=1
                Log.print("clicked version.... \(CloudRadioShareValues.hiddenCount)")
                if ( CloudRadioShareValues.hiddenCount >= 40 ) {
                    setUnlockFeature()
                }
            }
        }
    }
    
    private func checkDuplication(infos: [CRChannelInfo], title: String) -> Bool {
        for i in 0..<infos.count {
            if infos[i].title == title {
                Log.print("SKIP. \(title) -> DUPLICATE!")
                return true
            }
        }
        
        return false
    }
    
    private func loadCurrentChannels() {
        if let channels = CloudRadioUtils.loadChannelsJson() {
            Log.print("Load channels from JSON: \(channels.channels.count)")
            for i in 0..<channels.channels.count {
                var type: CHANNELTYPE = .RADIO
                var image = UIImage(systemName: "music.note")

                if channels.channels[i].type == 1 {
                    type = .YOUTUBEPLAYLIST
                    image = UIImage(systemName: "headphones")
                }
                let target = SideMenuModel(type: type, icon: image!, title: channels.channels[i].title, playlistId: channels.channels[i].playlistId)
                self.sideMenuData.menuMirror.insert(target, at: i)
            }
        }
    }
    
    private func saveChannels() {
        var channelInfo = [CRChannelInfo]()
        var type = 0
        
        // load channels from json
        self.loadCurrentChannels()
        
        // current
        for i in 0..<self.sideMenuData.menuMirror.count {
            if self.sideMenuData.menuMirror[i].type == .YOUTUBEPLAYLIST {
                type = 1
            } else {
                type = 0
            }
            let info = CRChannelInfo(type: type, title: self.sideMenuData.menuMirror[i].title, playlistId: self.sideMenuData.menuMirror[i].playlistId)
            Log.print("(CUR) ADD. \(info.title) ")
            channelInfo.append(info)
        }
        
        // unlocked channel (All radio)
        type = 0
        for i in 0..<self.sideMenuData.menu.count {
            let info = CRChannelInfo(type: type, title: self.sideMenuData.menu[i].title, playlistId: self.sideMenuData.menu[i].playlistId)
            // skip duplication
            if self.checkDuplication(infos: channelInfo, title: info.title) {
                continue
            }
            Log.print("(UNLOCKED) ADD. \(info.title) ")
            channelInfo.append(info)
        }
        
        let channels = CRChannels(channels: channelInfo)
        CloudRadioUtils.saveChannelInfoJson(data: channels)
    }
    
    func setUnlockFeature() {
        Log.print("unlock feature on!")
        
        // set version
        CloudRadioShareValues.versionString = CloudRadioShareValues.versionString + " (Awesome!)"
        body.text = CloudRadioShareValues.versionString
        CloudRadioShareValues.IsUnlockedFeature = true
        
        // save unlocked flag
        CloudRadioUtils.saveSettings()
        
        // save channels
        self.saveChannels()
        
        // stop radio
        NotificationCenter.default.post(name: .stopRadioMain, object: nil)
        
        // reset side menu
        NotificationCenter.default.post(name: .updateSideMenu, object: Int(999))
        
        // close setting view
        NotificationCenter.default.post(name: .closeSettingView, object: nil)
        
        // Making Alert
        NotificationCenter.default.post(name: .showAwesomeAlert, object: nil)
        
        // show home to update
        NotificationCenter.default.post(name: .updateAlbumArtMain, object: nil)
    }
    
    func goToContactToByEmail(address: String) {
        Log.print("Email clicked!: \(address)")
        if let url = URL(string: "mailto:\(address)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
}
