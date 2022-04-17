//
//  PlaylistSettingCell.swift
//  cloudRadio
//
//  Created by zerolive on 2022/03/22.
//

import UIKit


class PlaylistSettingCell: UITableViewCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var playlistSwitch: UISwitch!
    
    class var identifier: String { return String(describing: self) }
    class var nib: UINib { return UINib(nibName: identifier, bundle: nil) }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func onSwitchValueChanged(_ sender: Any) {
        if ( self.title.text == "랜덤 재생 설정" ) {
            Log.print("shuffle switch value: \(self.playlistSwitch.isOn)")
            CloudRadioShareValues.IsShuffle = self.playlistSwitch.isOn
        } else {
            Log.print("repeat switch value: \(self.playlistSwitch.isOn)")
            CloudRadioShareValues.IsRepeat = self.playlistSwitch.isOn
        }
    }

}
