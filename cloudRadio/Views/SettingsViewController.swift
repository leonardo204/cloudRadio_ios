//
//  SettingsViewController.swift
//  CustomSideMenuiOSExample
//
//  Created by John Codeos on 2/9/21.
//

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet var sideMenuBtn: UIBarButtonItem!

    @IBOutlet weak var settingTableView: UITableView!
    @IBOutlet weak var SettingViewHeaderLabel: UILabel!
    @IBOutlet weak var SettingBackButton: UIButton!
    
    
    var delegate: TimerTableViewCellDelegate? = nil
    
    var stopTimer: Timer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // title
        let f_imageAttachment = NSTextAttachment()
        f_imageAttachment.image = UIImage(named:"settings")
        let f_imageOffsetY: CGFloat = 0
        f_imageAttachment.bounds = CGRect(x: 0, y: f_imageOffsetY, width: 20, height: 20)
        let f_attachmentString = NSAttributedString(attachment: f_imageAttachment)
        let f_completeText = NSMutableAttributedString(string: "")
        f_completeText.append(f_attachmentString)
        let f_textAfterIcon = NSAttributedString(string: " Settings")
        f_completeText.append(f_textAfterIcon)
        self.SettingViewHeaderLabel.textAlignment = .center
        self.SettingViewHeaderLabel.numberOfLines = 0
        self.SettingViewHeaderLabel.baselineAdjustment = .alignCenters
        self.SettingViewHeaderLabel.textColor = UIColor.white
        self.SettingViewHeaderLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        self.SettingViewHeaderLabel.attributedText = f_completeText
        self.SettingViewHeaderLabel.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)

        self.settingTableView.delegate = self
        self.settingTableView.dataSource = self
        self.settingTableView.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)

        self.settingTableView.separatorStyle = .none
        
        self.settingTableView.estimatedSectionHeaderHeight =  .leastNormalMagnitude
        self.settingTableView.estimatedSectionFooterHeight =  .leastNormalMagnitude
        self.settingTableView.sectionFooterHeight =  UITableView.automaticDimension
        self.settingTableView.sectionHeaderHeight = UITableView.automaticDimension
        
        // cell nib register
        self.settingTableView.register(TimerTableViewCell.nib, forCellReuseIdentifier: TimerTableViewCell.identifier)
        self.settingTableView.register(ProgramInfoCell.nib, forCellReuseIdentifier: ProgramInfoCell.identifier)

        // back button
        self.SettingBackButton.setTitle("완료", for: .normal)
        self.SettingBackButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .medium)
    }
    
    @IBAction func SettingBackButtonClicked(_ sender: Any) {
        Log.print("SettingBackButtonClicked")
        self.dismiss(animated: true, completion: .none)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Log.print("viewDidAppear \(animated)")
        //CloudRadioShareValues.requestStopRadioTimer()
        NotificationCenter.default.post(name: .stopRadioTimerSettingsMain, object: nil)
    }

    
    override func viewDidDisappear(_ animated: Bool) {
        Log.print("viewDidDisappear \(animated)")
        CloudRadioShareValues.requestStopRadioTimer()

        CloudRadioShareValues.TimeLabel?.isHidden = true
        CloudRadioShareValues.TimeSlider?.isEnabled = false
        CloudRadioShareValues.TimeLabel = nil
        CloudRadioShareValues.TimeSlider = nil
        
        if ( CloudRadioShareValues.stopRadioSwitchisOn && CloudRadioShareValues.stopRadioTimerisActive ) {
            NotificationCenter.default.post(name: .startRadioTimerSettingsMain, object: nil)
        }
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = "Secion"
        switch section {
            case 0: title = "자동 종료 설정"
            case 1: title = "프로그램 정보"
            default: break;
        }
        return title
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // background color
        view.tintColor = .clear
        view.backgroundColor = .clear
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = .white
        header.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        // background color
        view.tintColor = .clear
        view.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = settingTableView.dequeueReusableCell(withIdentifier: "TimerCell", for: indexPath)
        var cell: UITableViewCell? = nil
        
//        Log.print("section: \(indexPath.section) row: \(indexPath.row)")
        
        if ( indexPath.section == 0 ) {
            if ( indexPath.row == 0 ) {
                guard let cell0 = tableView.dequeueReusableCell(withIdentifier: TimerTableViewCell.identifier, for: indexPath) as? TimerTableViewCell else { fatalError("TimerTableViewCell xib doesn't exist") }
                
                Log.print("making Setting table views. \(cell0.TimerSwitch.isOn) ")
                
                cell0.TimerTitle.text = "자동 종료 시간"
                cell0.TimerTitle.textColor = .white
                cell0.TimerTitle.font = UIFont.systemFont(ofSize: 12, weight: .medium)
                cell0.TimerSlider.maximumValue = 120*60
                if ( CloudRadioShareValues.stopRadioTimerTime > 0 ) {
                    cell0.TimerSlider.value = Float(CloudRadioShareValues.stopRadioTimerTime)
                } else {
                    cell0.TimerSlider.value = 60*60
                }
                cell0.TimerSlider.minimumValue = 0
                
                cell0.TimerSwitch.isOn = CloudRadioShareValues.stopRadioSwitchisOn
                cell0.TimeLabel.isHidden = !CloudRadioShareValues.stopRadioTimerisActive
                cell0.TimerSlider.isEnabled = CloudRadioShareValues.stopRadioTimerisActive
                        
                let myCustomSelectionColorView = UIView()
                myCustomSelectionColorView.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
                cell0.selectedBackgroundView = myCustomSelectionColorView
//                cell0.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
//                cell0.backgroundColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)

                cell = cell0
            } else {
                guard let cell0 = tableView.dequeueReusableCell(withIdentifier: TimerTableViewCell.identifier, for: indexPath) as? TimerTableViewCell else { fatalError("TimerTableViewCell xib doesn't exist") }
                cell = cell0
            }

        } else if ( indexPath.section == 1 ) {
            guard let cell1 = tableView.dequeueReusableCell(withIdentifier: ProgramInfoCell.identifier, for: indexPath) as? ProgramInfoCell else { fatalError("TimerTableViewCell xib doesn't exist") }
            if ( indexPath.row == 0 ) {
                cell1.title.text = "Version"
                cell1.body.text = CloudRadioShareValues.versionString
            } else {
                cell1.title.text = "Contact"
                let underlineAttriString = NSAttributedString(string: "zerolive7@gmail.com", attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
                cell1.body.attributedText = underlineAttriString
            }
            
            cell1.title.textColor = .white
            cell1.title.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            cell1.title.textAlignment = .left
//            cell1.title.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)

            cell1.body.textColor = .white
            cell1.body.font = UIFont.systemFont(ofSize: 15, weight: .bold)
            cell1.body.textAlignment = .left
//            cell1.body.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
            
            let myCustomSelectionColorView = UIView()
            myCustomSelectionColorView.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
            cell1.selectedBackgroundView = myCustomSelectionColorView
//            cell1.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)

            cell = cell1
        }
        
        cell?.backgroundColor = #colorLiteral(red: 0.2605174184, green: 0.2605243921, blue: 0.260520637, alpha: 1)
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if ( indexPath.section == 0 ){
            if ( indexPath.row == 0 ) {
                return 80
            } else {
                return 0
            }
        }
        return 40
    }
}
