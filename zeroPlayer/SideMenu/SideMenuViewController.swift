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
    @IBOutlet weak var EditLable: UILabel!
    @IBOutlet weak var addLable: UILabel!
    
    var delegate: SideMenuViewControllerDelegate?

    var defaultHighlightedCell: Int = 0
    var isChannelLoaded: Bool = false
    var isChannelAdded: Bool = false
   
    var sideMenuData = SideMenuDataModel()
    
    private var mainViewCon: MainViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                sideMenuData.menuMirror.insert(target, at: i)
                isChannelLoaded = true
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(finishEditingMode), name: Notification.Name("finishEdit"), object: nil)
                
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
        let imageOffsetY: CGFloat = -2
        imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: 20, height: 20)
        // Create string with attachment
        let attachmentString = NSAttributedString(attachment: imageAttachment)
        // Initialize mutable string
        let completeText = NSMutableAttributedString(string: "")
        // Add image to mutable string
        completeText.append(attachmentString)
        // Add your text to mutable string
        let textAfterIcon = NSAttributedString(string: " PlayLists")
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
        
        // adder
        let addText = NSMutableAttributedString(string: "+")
        self.addLable.textAlignment = .center
        self.addLable.baselineAdjustment = .alignCenters
        self.addLable.textColor = UIColor.white
        self.addLable.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        self.addLable.attributedText = addText
        self.addLable.isUserInteractionEnabled = true
        let addCell: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onClickedAddCell(recognizer:)))
        addCell.numberOfTapsRequired = 1
        self.addLable.addGestureRecognizer(addCell)
        
        // Edit
        let editText = NSMutableAttributedString(string: "...")

        self.EditLable.textAlignment = .center
        self.EditLable.baselineAdjustment = .alignCenters
        self.EditLable.textColor = UIColor.white
        self.EditLable.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        self.EditLable.attributedText = editText
        self.EditLable.isUserInteractionEnabled = true
        let editCell: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.onClickedEditCell(recognizer:)))
        editCell.numberOfTapsRequired = 1
        self.EditLable.addGestureRecognizer(editCell)

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
        
        Log.print("SideMenuViewController viewDidLoad")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Log.print("sideMenuView viewDidDisappear")
    }
    
    @objc func onClickedFooterSettingBtn(recognizer: UIGestureRecognizer) {
        self.delegate?.showSettingsScene()
    }
    
    @objc func onClickedEditCell(recognizer: UIGestureRecognizer) {
        Log.print("edit clicked")
        if self.sideMenuTableView.isEditing {
            self.sideMenuTableView.setEditing(false, animated: true)
            
            saveChannels()
        } else {
            self.sideMenuTableView.setEditing(true, animated: true)
        }
    }
    
    @objc func onClickedAddCell(recognizer: UIGestureRecognizer) {
        Log.print("add cell")
        let alert = UIAlertController(title: "Youtube Playlist ?????? ??????", message: "Playlist URL ??? ??????????????????.", preferredStyle: .alert)
        alert.addTextField { textFieldName in
            textFieldName.placeholder = "Playlist Name"
        }
        alert.addTextField { textFieldAddr in
            textFieldAddr.placeholder = "https://www.youtube.com/playlist?list=id"
        }
        alert.addAction(UIAlertAction(title: "??????", style: .default, handler: { _ in
            guard let name = alert.textFields?[0].text else { return }
            guard let addr = alert.textFields?[1].text else { return }
            if addr != "" {
                if addr.contains("youtube.com/playlist?list=") {
                    let id = addr[addr.endIndex(of: "youtube.com/playlist?list=")!..<addr.endIndex]
                    Log.print("add id: \(String(id))")
                    let item = SideMenuModel(type: .YOUTUBEPLAYLIST, icon: UIImage(systemName:"headphones")!, title: name, playlistId: String(id))
                    self.sideMenuData.menuMirror.insert(item, at: 0)
                    self.isChannelAdded = true

                    self.sideMenuTableView.beginUpdates()
                    self.sideMenuTableView.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .automatic)
                    self.sideMenuTableView.endUpdates()
                    
                    self.decideMenuMirror()
                    Log.print("self.menuMirror.count: \(self.sideMenuData.menuMirror.count)")
                    
                    self.saveChannels()
                } else {
                    let alertFailed = UIAlertController(title: "?????? ?????? ??????", message: "playlist URL ????????? ?????????????????????.", preferredStyle: .alert)
                    let okButton = UIAlertAction(title: "??????", style: UIAlertAction.Style.cancel, handler: nil)
                    alertFailed.addAction(okButton)
                    self.present(alertFailed, animated: true, completion: nil)
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "??????", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func saveChannels() {
        var channelInfo = [CRChannelInfo]()
        var type = 0
        for i in 0..<self.sideMenuData.menuMirror.count {
            if self.sideMenuData.menuMirror[i].type == .YOUTUBEPLAYLIST {
                type = 1
            } else {
                type = 0
            }
            let info = CRChannelInfo(type: type, title: self.sideMenuData.menuMirror[i].title, playlistId: self.sideMenuData.menuMirror[i].playlistId)
            channelInfo.insert(info, at: i)
        }
        let channels = CRChannels(channels: channelInfo)
        CloudRadioUtils.saveChannelInfoJson(data: channels)
    }
    
    @objc func finishEditingMode(notification: Notification) {
        Log.print("finishEditingMode")
        if self.sideMenuTableView.isEditing {
            self.sideMenuTableView.setEditing(false, animated: true)
            
            saveChannels()
        }
    }
}

// MARK: - UITableViewDelegate

extension SideMenuViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    //tableView??? ?????????????????? editing Control??? ????????? ????????? ????????? ???????????????. ??? ????????? editing Control??? ????????? ???????????? ???????????????.
    //????????? ????????? editing Control??? ????????? ????????????
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        Log.print("edit stype[\(indexPath.row)]: \(self.sideMenuData.menuMirror[indexPath.row].type)")
        if self.sideMenuData.menuMirror[indexPath.row].type == .RADIO {
            return .none //none????????? ?????? cell????????? ?????????????????? ??????. ?????? cell????????? editing control??? ???????????? ?????????
        }
        return .delete
    }
    
    //editing Control??? ?????? ????????? ?????????
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        if self.sideMenuData.menuMirror[indexPath.row].type == .RADIO {
            return false
        }
        return true
    }
}

// MARK: - UITableViewDataSource

extension SideMenuViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isChannelLoaded || isChannelAdded {
            return self.sideMenuData.menuMirror.count
        } else {
            if ( CloudRadioShareValues.IsUnlockedFeature ) {
                return self.sideMenuData.menu.count
            } else {
                return self.sideMenuData.lockedMenu.count
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: SideMenuCell.identifier, for: indexPath) as? SideMenuCell else { fatalError("xib doesn't exist") }
        
        if !isChannelLoaded && !isChannelAdded {
            Log.print("sideMenuBuild from STATIC")
            if ( CloudRadioShareValues.IsUnlockedFeature ) {
                cell.iconImageView.image = self.sideMenuData.menu[indexPath.row].icon
                cell.titleLabel.text = self.sideMenuData.menu[indexPath.row].title
                self.sideMenuData.menuMirror.insert(self.sideMenuData.menu[indexPath.row], at: indexPath.row)
            } else {
                cell.iconImageView.image = self.sideMenuData.lockedMenu[indexPath.row].icon
                cell.titleLabel.text = self.sideMenuData.lockedMenu[indexPath.row].title
                self.sideMenuData.menuMirror.insert(self.sideMenuData.lockedMenu[indexPath.row], at: indexPath.row)
            }
        } else {
            Log.print("sideMenuBuild from DYNAMIC \(self.sideMenuData.menuMirror[indexPath.row].title)")
            cell.iconImageView.image = self.sideMenuData.menuMirror[indexPath.row].icon
            cell.titleLabel.text = self.sideMenuData.menuMirror[indexPath.row].title
        }
        
        // Highlighted color
        let myCustomSelectionColorView = UIView()
        myCustomSelectionColorView.backgroundColor = #colorLiteral(red: 0.4756349325, green: 0.4756467342, blue: 0.4756404161, alpha: 1)
        cell.selectedBackgroundView = myCustomSelectionColorView
        cell.overrideUserInterfaceStyle = UIUserInterfaceStyle.dark
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if ( CloudRadioShareValues.isUnlocked ) {
//            self.delegate?.selectedCell(indexPath.row, title: SideMenuViewController.menu[indexPath.row].title)
//        } else {
//            self.delegate?.selectedCell(indexPath.row, title: SideMenuViewController.lockedMenu[indexPath.row].title)
//        }
        Log.print("select: \(self.sideMenuData.menuMirror[indexPath.row].title)")
        self.delegate?.selectedCell(indexPath.row, title: self.sideMenuData.menuMirror[indexPath.row].title)
    }
    
    //?????? ???????????? ????????? ????????? ????????? ??????????????? ???????????? ??????????????????. ????????? Reordering????????? ???????????? ????????? ??? ??????????????? true??? ???????????????
    //?????? cell??? ??????????????? ????????? ????????? ????????? ??????????????? indexPath??? ???????????? ?????? cell??? ????????????
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true //true??? ?????? cell??? ????????????
    }
    
    //????????? ?????? ???????????? ????????? ????????? ???????????? ??????????????? ???????????? ???????????? ?????????.
    //cell??? ????????? ?????? ????????? ????????? drop?????? ??? ???????????? ???????????????. ????????? ??????????????? ????????? ?????? ????????? ????????????, ????????? ??????????????? ????????? ?????? ????????? ???????????????.
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        //????????? ???????????? ???????????? ????????? ??????
        Log.print("Move src: \(sourceIndexPath.row) ->  dest: \(destinationIndexPath.row)")
        let target = self.sideMenuData.menuMirror.remove(at: sourceIndexPath.row)
        self.sideMenuData.menuMirror.insert(target, at: destinationIndexPath.row)
    }
    
    func decideMenuMirror() {
        for i in 0..<self.sideMenuData.menuMirror.count {
            if self.sideMenuData.menuMirror[i].type == .SAMPLE {
                Log.print("Remove SAMPLE")
                self.sideMenuData.menuMirror.remove(at: i)
                self.sideMenuTableView.deleteRows(at: [IndexPath.init(row: i, section: 0)], with: .fade)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.sideMenuData.menuMirror.remove(at: indexPath.row)
            self.sideMenuTableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
