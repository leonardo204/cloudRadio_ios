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
    var valueTime = CloudRadioShareValues.stopRadioTimerTime
    
    func setStopTimer(value: Double) {
        Log.print("setStopTimer: \(value)")
        stopTimerTimer()
   
        CloudRadioShareValues.stopRadioTimerisActive = true
        
        self.radioStopTimer = Timer.scheduledTimer(timeInterval: TimeInterval(value), target: self, selector: #selector(requestStopRadio), userInfo: nil, repeats: false)
        CloudRadioShareValues.stopRadioTimer = self.radioStopTimer

        CloudRadioShareValues.stopRadioTimerTime = value - 1
        self.drawTimeTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(drawTimerTime), userInfo: nil, repeats: true)
        CloudRadioShareValues.drawRadioTimeTimer = self.drawTimeTimer
    }
    
    func stopTimerTimer() {
        CloudRadioShareValues.stopRadioTimerisActive = false
        
        if ( CloudRadioShareValues.stopRadioTimer?.isValid ) != nil {
            CloudRadioShareValues.stopRadioTimer?.invalidate()
            CloudRadioShareValues.stopRadioTimer = nil
        }

        if ( CloudRadioShareValues.drawRadioTimeTimer?.invalidate() ) != nil {
            CloudRadioShareValues.drawRadioTimeTimer?.invalidate()
            CloudRadioShareValues.drawRadioTimeTimer = nil
        }
    }
    
    @objc func drawTimerTime(timer: Timer) {
        if ( CloudRadioShareValues.stopRadioTimerTime > 0 ) {
            let valuestring = CloudRadioUtils.getUTCDateString(timevalue: CloudRadioShareValues.stopRadioTimerTime)
            Log.print("drawTimerTime Going \(valuestring)")

            CloudRadioShareValues.TimeLabel?.text = valuestring
            CloudRadioShareValues.TimeSlider?.value = Float(CloudRadioShareValues.stopRadioTimerTime)
            CloudRadioShareValues.stopRadioTimerTime -= 1
//            CloudRadioShareValues.stopRadioTimerTime = valueTime
        } else {
            Log.print("drawTimerTime End \(valueTime)")

            CloudRadioShareValues.drawRadioTimeTimer?.invalidate()
            CloudRadioShareValues.drawRadioTimeTimer = nil
        }
    }
    
    @IBAction func TimerSwitchValueChanged(_ sender: Any) {
        Log.print("switch. \(self.TimerSwitch.isOn)")
        CloudRadioShareValues.stopRadioSwitchisOn = self.TimerSwitch.isOn
        
        if ( self.TimerSwitch.isOn ) {
            CloudRadioShareValues.TimeLabel = self.TimeLabel
            CloudRadioShareValues.TimeSlider = self.TimerSlider
            CloudRadioShareValues.TimeLabel?.isHidden = false
            CloudRadioShareValues.TimeSlider?.isEnabled = true
            CloudRadioShareValues.TimeSlider?.minimumTrackTintColor = .systemBlue


            let valuestring = CloudRadioUtils.getUTCDateString(timevalue: Double(round(CloudRadioShareValues.TimeSlider!.value)))
            let value = Double(round(CloudRadioShareValues.TimeSlider!.value))
            setStopTimer(value: value)

            CloudRadioShareValues.TimeLabel?.text = valuestring
            CloudRadioShareValues.TimeLabel?.textColor = .white
            CloudRadioShareValues.TimeLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        } else {
            CloudRadioShareValues.TimeLabel?.isHidden = true
            CloudRadioShareValues.TimeSlider?.isEnabled = false
            CloudRadioShareValues.TimeSlider?.minimumTrackTintColor = .gray
            CloudRadioShareValues.TimeLabel = nil
            CloudRadioShareValues.TimeSlider = nil
            stopTimerTimer()
        }
    }
    
    @objc func onSliderValChanged(slider: UISlider, event: UIEvent) {
        let valuestring = CloudRadioUtils.getUTCDateString(timevalue: Double(round(self.TimerSlider.value)))

        if let touchEvent = event.allTouches?.first {
            switch touchEvent.phase {
            case .began:
                Log.print("onSliderVal began")
            case .moved:
                Log.print("onSliderVal moved: \(valuestring)")
                self.TimeLabel.text = valuestring
                stopTimerTimer()
            case .ended:
                Log.print("onSliderVal ended: \(valuestring)")
                let value = Double(round(self.TimerSlider.value))
                setStopTimer(value: value)
            default:
                break
            }
        }
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
        
        // initialize
        if CloudRadioShareValues.TimeLabel == nil {
            CloudRadioShareValues.TimeLabel = self.TimeLabel
        }
        
        if CloudRadioShareValues.TimeSlider == nil {
            CloudRadioShareValues.TimeSlider = self.TimerSlider
        }

        
        if ( CloudRadioShareValues.stopRadioTimerisActive ) {
            stopTimerTimer()
            
            CloudRadioShareValues.TimeLabel?.isHidden = false
            CloudRadioShareValues.TimeSlider?.isEnabled = true
            
            let valuestring = CloudRadioUtils.getUTCDateString(timevalue: Double(CloudRadioShareValues.stopRadioTimerTime))
            Log.print("restart stopRadioTimer w/ \(valuestring)")

            let value = Double(Double(CloudRadioShareValues.stopRadioTimerTime))
            setStopTimer(value: value)

            CloudRadioShareValues.TimeLabel?.text = valuestring
            CloudRadioShareValues.TimeLabel?.textColor = .white
            CloudRadioShareValues.TimeLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            CloudRadioShareValues.TimeSlider?.value = Float(CloudRadioShareValues.stopRadioTimerTime)
            CloudRadioShareValues.TimeSlider?.minimumTrackTintColor = .systemBlue
        } else {
            CloudRadioShareValues.TimeLabel?.isHidden = true
            CloudRadioShareValues.TimeSlider?.isEnabled = false
            CloudRadioShareValues.TimeSlider?.minimumTrackTintColor = .gray
        }
        
        TimerSlider.addTarget(self, action: #selector(onSliderValChanged(slider:event:)), for: .valueChanged)

    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
