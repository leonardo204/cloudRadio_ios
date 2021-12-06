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

        self.settingTableView.delegate = self
        self.settingTableView.dataSource = self
        self.settingTableView.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
        self.settingTableView.separatorStyle = .none
//        let nibName = UINib(nibName: "TimerTableViewCell", bundle: nil)
        self.settingTableView.register(TimerTableViewCell.nib, forCellReuseIdentifier: TimerTableViewCell.identifier)

    }
    
    override func viewDidAppear(_ animated: Bool) {
        Log.print("viewDidAppear \(animated)")
        //CloudRadioShareValues.requestStopRadioTimer()
        NotificationCenter.default.post(name: .stopRadioTimerSettingsMain, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        Log.print("viewDidDisappear \(animated)")
        CloudRadioShareValues.requestStopRadioTimer()

        if ( CloudRadioShareValues.stopRadioSwitchisOn && CloudRadioShareValues.stopRadioTimerisActive ) {
            NotificationCenter.default.post(name: .startRadioTimerSettingsMain, object: nil)
        }
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var title = "Secion"
        switch section {
            case 0: title = "자동 종료 설정"
            default: break;
        }
        return title
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        // background color
        view.tintColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        let header : UITableViewHeaderFooterView = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = .white
        header.textLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = settingTableView.dequeueReusableCell(withIdentifier: "TimerCell", for: indexPath)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TimerTableViewCell.identifier, for: indexPath) as? TimerTableViewCell else { fatalError("TimerTableViewCell xib doesn't exist") }
        
        Log.print("making Setting table views. \(cell.TimerSwitch.isOn)")
        
        cell.TimerTitle.text = "자동 종료 시간"
        cell.TimerTitle.textColor = .white
        cell.TimerTitle.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        cell.TimerSlider.maximumValue = 120*60
        if ( CloudRadioShareValues.stopRadioTimerTime > 0 ) {
            cell.TimerSlider.value = Float(CloudRadioShareValues.stopRadioTimerTime)
        } else {
            cell.TimerSlider.value = 60*60
        }
        cell.TimerSlider.minimumValue = 0
        
        cell.TimerSwitch.isOn = CloudRadioShareValues.stopRadioSwitchisOn
        cell.TimeLabel.isHidden = !CloudRadioShareValues.stopRadioTimerisActive
        cell.TimerSlider.isEnabled = CloudRadioShareValues.stopRadioTimerisActive
                
        let myCustomSelectionColorView = UIView()
        myCustomSelectionColorView.backgroundColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
        cell.selectedBackgroundView = myCustomSelectionColorView
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
