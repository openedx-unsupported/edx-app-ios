//
//  RegistrationAgreementView.swift
//  edX
//
//  Created by Muhammad Zeeshan Arif on 27/11/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class RegistrationAgreementView: UIView {
    
    private var paddingHorizontol: CGFloat = 40.0
    private var verticleSpace: CGFloat = 3.0
    private var paddingTop:CGFloat = 0.0
    private var buttonHeight:CGFloat = 30.0
    
    // Properties
    let formErrorLabelStyle = OEXTextStyle(weight: .normal, size: .small, color: UIColor.red)
    let formInstructionLabelStyle = OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralDark())
    let formAgreementButtonStyle = OEXTextStyle(weight: .normal, size: .small, color: UIColor.blue)
    
    private var formField: OEXRegistrationFormField? {
        didSet{
            lblInstruction.attributedText = formInstructionLabelStyle.attributedString(withText: formField?.instructions ?? "")
            btnAggreement.setAttributedTitle(formAgreementButtonStyle.attributedString(withText: formField?.agreement.text ?? ""), for: .normal)
            lblInstruction.sizeToFit()
        }
    }
    var errorMessage: String? = ""{
        didSet{
            lblErrorMessage.attributedText = formErrorLabelStyle.attributedString(withText: errorMessage ?? "")
        }
    }
    
    // UI Properties
    lazy private var lblErrorMessage: UILabel = {
        let label = UILabel()
        label.applyLabelDefaults()
        return label
    }()
    
    lazy private var lblInstruction: UILabel = {
        let label = UILabel()
        label.applyLabelDefaults()
        return label
    }()
    
    lazy private var btnAggreement: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = false
        return button
    }()
    
    // Initializers
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init(with formField: OEXRegistrationFormField){
        super.init(frame: CGRect.zero)
        self.formField = formField
        load()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Super View is not constraint base. So need to call sizeToFit on labels to show layout properly. As Superviews height is calculated after randering views.
        lblErrorMessage.sizeToFit()
        lblInstruction.sizeToFit()
        
        var frame = self.frame
        frame.size.height = buttonHeight + lblInstruction.frame.size.height + lblErrorMessage.frame.size.height + StandardVerticalMargin + (2 * verticleSpace)
        self.frame = frame
    }
    
    private func load() {
        addSubviews()
        setupConstraints()
    }

    private func addSubviews(){
        addSubview(btnAggreement)
        addSubview(lblErrorMessage)
        addSubview(lblInstruction)
    }
    private func setupConstraints(){
        btnAggreement.snp_makeConstraints { (maker) in
            maker.top.equalTo(paddingTop)
            maker.leading.equalTo(self).offset(paddingHorizontol)
            maker.trailing.equalTo(self).inset(paddingHorizontol)
            maker.height.equalTo(buttonHeight)
        }
        
        lblErrorMessage.snp_makeConstraints { (maker) in
            maker.leading.equalTo(btnAggreement.snp_leading)
            maker.trailing.equalTo(btnAggreement.snp_trailing)
            maker.top.equalTo(btnAggreement.snp_bottom).offset(verticleSpace)
        }
        
        lblInstruction.snp_makeConstraints { (maker) in
            maker.leading.equalTo(btnAggreement.snp_leading)
            maker.trailing.equalTo(btnAggreement.snp_trailing)
            maker.top.equalTo(lblErrorMessage.snp_bottom).offset(verticleSpace)
            maker.bottom.equalTo(snp_bottom).inset(StandardVerticalMargin)
        }
    }
    func currentValue() -> Bool {
        // Return true by default
        return true
    }
    
    func clearError (){
        errorMessage = nil
    }

}
