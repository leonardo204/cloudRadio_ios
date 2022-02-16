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
            if ( !CloudRadioShareValues.isUnlocked ) {
                CloudRadioShareValues.hiddenCount+=1
                print("clicked version.... \(CloudRadioShareValues.hiddenCount)")
                if ( CloudRadioShareValues.hiddenCount >= 40 ) {
                    setUnlockFeature()
                }
            }
        }
    }
    
    func setUnlockFeature() {
        CloudRadioShareValues.versionString = CloudRadioShareValues.versionString + " (Awesome!)"
        body.text = CloudRadioShareValues.versionString
        CloudRadioShareValues.isUnlocked = true
        
        let appInfo = CRAppInfo(isUnlocked: true)
        
        CloudRadioUtils.saveJsonData(data: appInfo)
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
