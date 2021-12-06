//
//  TimerTableViewCell.swift
//  cloudRadio
//
//  Created by zerolive on 2021/12/06.
//

import UIKit

protocol TimerTableViewCellDelegate {
    func stopTimerTimerDelegate()
}

extension TimerTableViewCell: TimerTableViewCellDelegate {
    func stopTimerTimerDelegate() {
        Log.print("stopTimerTimerDelegate")
        stopTimerTimer()
    }
}

class TimerTableViewCell: UITableViewCell {

    @IBOutlet weak var TimerTitle: UILabel!
    @IBOutlet weak var TimeLabel: UILabel!
    @IBOutlet weak var TimerSlider: UISlider!
    @IBOutlet weak var TimerSwitch: UISwitch!
    
    var radioStopTimer: Timer? = nil
    var drawTimeTimer: Timer? = nil
    var valueTime = 0.0
    
    func setStopTimer(value: Double) {
        Log.print("setStopTimer: \(value)")
        stopTimerTimer()
   
        CloudRadioShareValues.stopRadioTimerisActive = true
        
        self.radioStopTimer = Timer.scheduledTimer(timeInterval: TimeInterval(value), target: self, selector: #selector(requestStopRadio), userInfo: nil, repeats: false)
        CloudRadioShareValues.stopRadioTimer = self.radioStopTimer

        valueTime = value - 1
        self.drawTimeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(drawTimerTime), userInfo: nil, repeats: true)
        CloudRadioShareValues.drawRadioTimeTimer = self.drawTimeTimer
    }
    
    func stopTimerTimer() {
        CloudRadioShareValues.stopRadioTimerisActive = false
        
        if ( self.radioStopTimer?.isValid ) != nil {
            self.radioStopTimer?.invalidate()
            self.radioStopTimer = nil
            CloudRadioShareValues.stopRadioTimer = nil
        }

        if ( self.drawTimeTimer?.invalidate() ) != nil {
            self.drawTimeTimer?.invalidate()
            self.drawTimeTimer = nil
            CloudRadioShareValues.drawRadioTimeTimer = nil
        }
    }
    
    @objc func drawTimerTime(timer: Timer) {
        if ( valueTime > 0 ) {
            let valuestring = CloudRadioUtils.getUTCDateString(timevalue: valueTime)
            Log.print("drawTimerTime Going \(valuestring)")

            self.TimeLabel.text = valuestring
            self.TimerSlider.value = Float(valueTime)
            valueTime -= 1
            CloudRadioShareValues.stopRadioTimerTime = valueTime
        } else {
            Log.print("drawTimerTime End \(valueTime)")

            self.drawTimeTimer?.invalidate()
            self.drawTimeTimer = nil
            CloudRadioShareValues.drawRadioTimeTimer = nil
        }
    }
    
    @IBAction func TimerSwitchValueChanged(_ sender: Any) {
        Log.print("switch. \(self.TimerSwitch.isOn)")
        CloudRadioShareValues.stopRadioSwitchisOn = self.TimerSwitch.isOn
        
        if ( self.TimerSwitch.isOn ) {
            self.TimeLabel.isHidden = false
            self.TimerSlider.isEnabled = true

            let valuestring = CloudRadioUtils.getUTCDateString(timevalue: Double(round(self.TimerSlider.value)))
            let value = Double(round(self.TimerSlider.value))
            setStopTimer(value: value)

            self.TimeLabel.text = valuestring
            self.TimeLabel.textColor = .white
            self.TimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        } else {
            self.TimeLabel.isHidden = true
            self.TimerSlider.isEnabled = false
            stopTimerTimer()
        }
    }
    @IBAction func TimerSliderValueChanged(_ sender: Any) {
        let valuestring = CloudRadioUtils.getUTCDateString(timevalue: Double(round(self.TimerSlider.value)))
        let value = Double(round(self.TimerSlider.value))
//        Log.print("slider. \(valuestring)")
        if ( self.TimerSwitch.isOn ) {
            self.TimeLabel.text = valuestring
        }
        setStopTimer(value: value)
    }
    
    @objc func requestStopRadio(timer: Timer) {
        Log.print("Called requestStopRadio")
        NotificationCenter.default.post(name: .stopRadioMain, object: nil)
    }
    
    class var identifier: String { return String(describing: self) }
    class var nib: UINib { return UINib(nibName: identifier, bundle: nil) }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // Background
        self.backgroundColor = .clear
        
        if ( CloudRadioShareValues.stopRadioTimerisActive ) {
            self.TimeLabel.isHidden = false
            self.TimerSlider.isEnabled = true

            let valuestring = CloudRadioUtils.getUTCDateString(timevalue: Double(CloudRadioShareValues.stopRadioTimerTime))
            Log.print("restart stopRadioTimer w/ \(valuestring)")

            let value = Double(Double(CloudRadioShareValues.stopRadioTimerTime))
            setStopTimer(value: value)

            self.TimeLabel.text = valuestring
            self.TimeLabel.textColor = .white
            self.TimeLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
