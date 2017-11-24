//
//  RegistrationFieldSelectView.swift
//  edX
//
//  Created by Akiva Leffert on 6/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class RegistrationFieldSelectView: OEXRegistrationFormTextField, UIPickerViewDelegate, UIPickerViewDataSource {
    var options : [OEXRegistrationOption] = []
    private(set) var selected : OEXRegistrationOption?
    
    @objc let picker = UIPickerView(frame: CGRect.zero)
    private let dropdownTab = UIImageView()
    private let tapButton = UIButton()
    
    
    private var titleStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
    }
    
    override init(frame : CGRect) {
        super.init(frame : CGRect.zero)
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true;
        textInputView.isEnabled = false
        
        dropdownTab.image = Icon.Dropdown.imageWithFontSize(size: 12)
        dropdownTab.tintColor = OEXStyles.shared().neutralDark()
        dropdownTab.sizeToFit()
        
        tapButton.localizedHorizontalContentAlignment = .Leading
        
        if isRightToLeft && !UIDevice.isOSVersionAtLeast9() {
            // Starting with iOS9, leftView and rightView are reflected in RTL views.
            // When we drop iOS8 support we can remove this conditional check entirely.
            textInputView.leftViewMode = .always
            textInputView.leftView = dropdownTab
        }
        else {
            textInputView.rightViewMode = .always
            textInputView.rightView = dropdownTab
        }
        tapButton.oex_addAction({[weak self] _ in
            self?.makeFirstResponder()
            }, for: UIControlEvents.touchUpInside)
        self.addSubview(tapButton)
        
        tapButton.snp_makeConstraints { (make) in
            make.top.equalTo(textInputView)
            make.leading.equalTo(textInputView)
            make.trailing.equalTo(textInputView)
            make.bottom.equalTo(textInputView)
        }
        
        self.textInputView.isAccessibilityElement = false
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tapButton.accessibilityTraits = UIAccessibilityTraitNone
        tapButton.accessibilityHint = String(format: "%@, %@", instructionMessage, Strings.accessibilityShowsDropdownHint)
        setButtonTitle(title: placeholder)
        
    }
    
    private func setButtonTitle(title: String) {
        tapButton.setAttributedTitle(titleStyle.attributedString(withText: title), for: .normal)
        tapButton.accessibilityLabel = String(format: "%@, %@", title, Strings.accessibilityDropdownTrait)
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var inputView : UIView {
        return picker
    }
      
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.options[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selected = self.options[row]
        if let selected = self.selected, !selected.value.isEmpty {
            setButtonTitle(title: selected.name)
        }
        else {
            setButtonTitle(title: placeholder)
        }
    }
    
    func makeFirstResponder() {
        self.becomeFirstResponder()
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.picker)
    }

}
