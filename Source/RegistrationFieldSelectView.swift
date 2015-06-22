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
    
    private let picker = UIPickerView(frame: CGRectZero)
    private let dropdownTab = UIImageView()
    
    init() {
        super.init(frame : CGRectZero)
        picker.dataSource = self
        picker.delegate = self
        picker.showsSelectionIndicator = true;
        inputView.inputView = picker
        
        dropdownTab.image = Icon.Dropdown.imageWithFontSize(12)
        dropdownTab.tintColor = OEXStyles.sharedStyles().neutralDark()
        
        addSubview(dropdownTab)
        
        dropdownTab.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(inputView).offset(-10)
            make.centerY.equalTo(inputView)
        }
    }
      
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options.count
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return self.options[row].name
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.selected = self.options[row]
        if let selected = self.selected where !selected.value.isEmpty {
            self.inputView.text = selected.name
        }
        else {
            self.inputView.text = ""
        }
    }

}