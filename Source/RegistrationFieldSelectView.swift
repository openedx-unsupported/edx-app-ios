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
    
    override var currentValue: String {
        return tapButton.attributedTitle(for: .normal)?.string ?? ""
    }
    
    override init(with formField: OEXRegistrationFormField) {
        super.init(with: formField)
    }
    
    override func loadView() {
        super.loadView()
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true;
        picker.accessibilityIdentifier = "RegistrationFieldSelectView:picker-view"
        textInputField.isEnabled = false
        dropdownView.addSubview(dropdownTab)
        dropdownView.layoutIfNeeded()
        dropdownTab.image = Icon.Dropdown.imageWithFontSize(size: 12)
        dropdownTab.tintColor = OEXStyles.shared().neutralDark()
        dropdownTab.contentMode = .scaleAspectFit
        dropdownTab.sizeToFit()
        dropdownTab.center = dropdownView.center
        tapButton.localizedHorizontalContentAlignment = .Leading
        textInputField.rightViewMode = .always
        textInputField.rightView = dropdownView
        tapButton.oex_addAction({[weak self] _ in
            self?.makeFirstResponder()
            }, for: UIControlEvents.touchUpInside)
        self.addSubview(tapButton)
        
        tapButton.snp.makeConstraints { make in
            make.top.equalTo(textInputField)
            make.leading.equalTo(textInputField)
            make.trailing.equalTo(textInputField)
            make.bottom.equalTo(textInputField)
        }
        let insets = OEXStyles.shared().standardTextViewInsets
        tapButton.titleEdgeInsets = UIEdgeInsetsMake(0, insets.left, 0, insets.right)
        refreshAccessibilty()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    override func refreshAccessibilty() {
        guard let formField = formField else { return }
        
        let errorAccessibility = errorMessage ?? "" != "" ? ",\(Strings.Accessibility.errorText), \(errorMessage ?? "")" : ""
        tapButton.accessibilityLabel = String(format: "%@, %@", formField.label, Strings.accessibilityDropdownTrait)
        tapButton.accessibilityTraits = UIAccessibilityTraitNone
        let accessibilitHintText = isRequired ? String(format: "%@, %@, %@, %@", Strings.Accessibility.requiredInput,formField.instructions, errorAccessibility , Strings.accessibilityShowsDropdownHint) : String(format: "%@, %@, %@, %@", Strings.Accessibility.optionalInput,formField.instructions,errorAccessibility , Strings.accessibilityShowsDropdownHint)
        tapButton.accessibilityHint = accessibilitHintText
        textInputField.isAccessibilityElement = false
        textInputField.accessibilityIdentifier = "RegistrationFieldSelectView:text-input-field"
    }
    
    private func setButtonTitle(title: String) {
        tapButton.setAttributedTitle(titleStyle.attributedString(withText: title), for: .normal)
        tapButton.accessibilityLabel = String(format: "%@, %@, %@", formField?.label ?? "", title, Strings.accessibilityDropdownTrait)
        tapButton.accessibilityIdentifier = "RegistrationFieldSelectView:\(String(describing: formField?.name))-\(title)-dropdown"
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
        valueDidChange()
    }
    
    func makeFirstResponder() {
        self.becomeFirstResponder()
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.picker)
    }
    
    override func validate() -> String? {
        guard let field = formField else {
            return nil
        }
        if isRequired && currentValue == "" {
            return field.errorMessage.required == "" ? Strings.registrationFieldEmptySelectError(fieldName: field.label) : field.errorMessage.required
        }
        return nil
    }

}
