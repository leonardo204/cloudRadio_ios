//
//  SideMenuViewController.swift
//  CustomSideMenuiOSExample
//
//  Created by John Codeos on 2/7/21.
//

import UIKit

protocol SideMenuViewControllerDelegate {
    func selectedCell(_ row: Int, title: String)
    func returnHomeScene()
    func showSettingsScene()
}

class SideMenuViewController: UIViewController {
    @IBOutlet var headerImageView: UIImageView!
    @IBOutlet var sideMenuTableView: UITableView!
    @IBOutlet weak var footerSettingBtn: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var footerLabel: UILabel!
    
    var delegate: SideMenuViewControllerDelegate?

    var defaultHighlightedCell: Int = 0

    static var menu: [SideMenuModel] = [
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "KBS Classic FM"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "MBC FM For U"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "KBS Cool FM"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "SBS Love FM"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "SBS Power FM"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "MBC Standard FM"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "KBS Happy FM"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "KBS1 Radio"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "CBS Music"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "TBS FM"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "AFN The Eagle"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "AFN The Voice"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "AFN Joe Radio"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "AFN Legacy")
    ]
    
    static var lockedMenu: [SideMenuModel] = [
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "AFN The Eagle"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "AFN The Voice"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "AFN Joe Radio"),
        SideMenuModel(icon: UIImage(systemName: "music.note")!, title: "AFN Legacy")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // TableView
        self.sideMenuTableView.delegate = self
        self.sideMenuTableView.dataSource = self
        self.sideMenuTableView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        self.sideMenuTableView.separatorStyle = .none

        // Set Highlighted Cell
        DispatchQueue.main.async {
            let defaultRow = IndexPath(row: self.defaultHighlightedCell, section: 0)
            self.sideMenuTableView.selectRow(at: defaultRow, animated: false, scrollPosition: .none)
        }
        
        // Header
        // Create Attachment
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = UIImage(named:"sound-wave")
        // Set bound to reposition
        let imageOffsetY: CGFloat = 0
        imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: 20, height: 20)
        // Create string with attachment
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        // Initialize mutable string
        let completeText = NSMutableAttributedString(string: "")
        // Add image to mutable string
        completeText.append(attachmentString)
        // Add your text to mutable string
        let textAfterIcon = NSAttributedString(string: " CloudRadio")
        completeText.append(textAfterIcon)
        self.headerLabel.textAlignment = .center
        self.headerLabel.baselineAdjustment = .alignBaselines
        self.headerLabel.textColor = UIColor.white
        self.headerLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        self.headerLabel.attributedText = completeText
//        self.headerLabel.sizeToFit()
//        self.headerLabel.textColor = UIColor.white
//        self.headerLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
//        self.headerLabel.text = "cloudRadio"
        
        

        // Footer
        let f_imageAttachment = NSTextAttachment()
        f_imageAttachment.image = UIImage(named:"settings")
        let f_imageOffsetY: CGFloat = 0
        f_imageAttachment.bounds = CGRect(x: 0, y: f_imageOffsetY, width: 20, height: 20)
        let f_attachmentString = NSAttributedString(attachment: f_imageAttachment)
        let f_completeText = NSMutableAttributedString(string: "")
        f_completeText.append(f_attachmentString)
        let f_textAfterIcon = NSAttributedString(string: " Settings")
        f_completeText.append(f_textAfterIcon)
        self.footerLabel.textAlignment = .center
        self.footerLabel.numberOfLines = 0
        self.footerLabel.baselineAdjustment = .alignCenters
        self.footerLabel.textColor = UIColor.white
        self.footerLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        self.footerLabel.attributedText = f_completeText
        
        // register action
        self.footerLabel.isUserInteractionEnabled = true
        let footer: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onClickedFooterSettingBtn(recognizer:)))
        footer.numberOfTapsRequired = 1
        self.footerLabel.addGestureRecognizer(footer)

        // Register TableView Cell
        self.sideMenuTableView.register(SideMenuCell.nib, forCellReuseIdentifier: SideMenuCell.identifier)

        // Update TableView with the data
        self.sideMenuTableView.reloadData()
    }
    
    @objc func onClickedFooterSettingBtn(recognizer: UIGestureRecognizer) {
        self.delegate?.showSettingsScene()
    }
}

// MARK: - UITableViewDelegate

extension SideMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

// MARK: - UITableViewDataSource

extension SideMenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if ( CloudRadioShareValues.isUnlocked ) {
            return SideMenuViewController.menu.count
        } else {
            return SideMenuViewController.lockedMenu.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SideMenuCell.identifier, for: indexPath) as? SideMenuCell else { fatalError("xib doesn't exist") }
                
        if ( CloudRadioShareValues.isUnlocked ) {
            cell.iconImageView.image = SideMenuViewController.menu[indexPath.row].icon
            cell.titleLabel.text = SideMenuViewController.menu[indexPath.row].title
        } else {
            cell.iconImageView.image = SideMenuViewController.lockedMenu[indexPath.row].icon
            cell.titleLabel.text = SideMenuViewController.lockedMenu[indexPath.row].title
        }
        // Highlighted color
        let myCustomSelectionColorView = UIView()
        myCustomSelectionColorView.backgroundColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        cell.selectedBackgroundView = myCustomSelectionColorView
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if ( CloudRadioShareValues.isUnlocked ) {
            self.delegate?.selectedCell(indexPath.row, title: SideMenuViewController.menu[indexPath.row].title)
        } else {
            self.delegate?.selectedCell(indexPath.row, title: SideMenuViewController.lockedMenu[indexPath.row].title)
        }
        // Remove highlighted color when you press the 'Profile' and 'Like us on facebook' cell
//        if indexPath.row == 4 || indexPath.row == 6 {
//            tableView.deselectRow(at: indexPath, animated: true)
//        }
    }
    
}
