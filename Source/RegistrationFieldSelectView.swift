//
//  RegistrationFieldSelectView.swift
//  edX
//
//  Created by Akiva Leffert on 6/9/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class RegistrationFieldSelectView: RegistrationFormFieldView, UIPickerViewDelegate, UIPickerViewDataSource {
    var options : [OEXRegistrationOption] = []
    private(set) var selected : OEXRegistrationOption?
    
    @objc let picker = UIPickerView(frame: CGRect.zero)
    private let dropdownView = UIView(frame: CGRect(x: 0, y: 0, width: 27, height: 40))
    private let dropdownTab = UIImageView()
    private let tapButton = UIButton()
    
    
    private var titleStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
    }
    
    override init(frame : CGRect) {
        super.init(frame : CGRect.zero)
    }
    
    convenience init(with formField: OEXRegistrationFormField){
        self.init(frame: CGRect.zero)
        self.formField = formField
        load()
    }
    
    override func load() {
        super.load()
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true;
        textInputField.isEnabled = false
        dropdownView.addSubview(dropdownTab)
        dropdownView.layoutIfNeeded()
        dropdownTab.image = Icon.Dropdown.imageWithFontSize(size: 12)
        dropdownTab.tintColor = OEXStyles.shared().neutralDark()
        dropdownTab.contentMode = .scaleAspectFit
        dropdownTab.sizeToFit()
        dropdownTab.center = dropdownView.center
        tapButton.localizedHorizontalContentAlignment = .Leading
        
        if isRightToLeft && !UIDevice.isOSVersionAtLeast9() {
            // Starting with iOS9, leftView and rightView are reflected in RTL views.
            // When we drop iOS8 support we can remove this conditional check entirely.
            textInputField.leftViewMode = .always
            textInputField.leftView = dropdownView
        }
        else {
            textInputField.rightViewMode = .always
            textInputField.rightView = dropdownView
        }
        tapButton.oex_addAction({[weak self] _ in
            self?.makeFirstResponder()
            }, for: UIControlEvents.touchUpInside)
        self.addSubview(tapButton)
        
        tapButton.snp_makeConstraints { (make) in
            make.top.equalTo(textInputField)
            make.leading.equalTo(textInputField)
            make.trailing.equalTo(textInputField)
            make.bottom.equalTo(textInputField)
        }
        
        self.textInputField.isAccessibilityElement = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tapButton.accessibilityTraits = UIAccessibilityTraitNone
        if let formField = formField{
            tapButton.accessibilityHint = String(format: "%@, %@", formField.label, Strings.accessibilityShowsDropdownHint)
        }
        else{
            tapButton.accessibilityHint = String(format: "%@", Strings.accessibilityShowsDropdownHint)
        }
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
            setButtonTitle(title: "")
        }
    }
    
    func makeFirstResponder() {
        self.becomeFirstResponder()
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.picker)
    }

}
