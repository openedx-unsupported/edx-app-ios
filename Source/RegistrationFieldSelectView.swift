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
    
    @objc let picker = UIPickerView(frame: CGRectZero)
    private let dropdownTab = UIImageView()
    private let tapButton = UIButton()
    
    override init(frame : CGRect) {
        super.init(frame : CGRectZero)
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true;
        textInputView.enabled = false
        
        dropdownTab.image = Icon.Dropdown.imageWithFontSize(12)
        dropdownTab.tintColor = OEXStyles.sharedStyles().neutralDark()
        dropdownTab.sizeToFit()
        
        if isRightToLeft && !UIDevice.isOSVersionAtLeast9() {
            // Starting with iOS9, leftView and rightView are reflected in RTL views.
            // When we drop iOS8 support we can remove this conditional check entirely.
            textInputView.leftViewMode = .Always
            textInputView.leftView = dropdownTab
        }
        else {
            textInputView.rightViewMode = .Always
            textInputView.rightView = dropdownTab
        }
        tapButton.oex_addAction({[weak self] _ in
            self?.makeFirstResponder()
            }, forEvents: UIControlEvents.TouchUpInside)
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
        tapButton.accessibilityLabel = self.placeholder
        tapButton.accessibilityHint = Strings.accessibilityShowsDropdownHint
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override var inputView : UIView {
        return picker
    }
      
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.options[row].name
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selected = self.options[row]
        if let selected = self.selected where !selected.value.isEmpty {
            self.textInputView.text = selected.name
        }
        else {
            self.textInputView.text = ""
        }
    }
    
    func makeFirstResponder() {
        self.becomeFirstResponder()
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.picker)
    }

}