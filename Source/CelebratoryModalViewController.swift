//
//  CelebratoryModalViewController.swift
//  edX
//
//  Created by Salman on 22/01/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

class CelebratoryModalViewController: UIViewController {

    private let modalView = UIView()
    var clappingImage:UIImageView? = nil
    
    private lazy var congratulationImageView: UIImageView = {
        let gifImage = UIImage.gifImageWithName("CelebrateClaps")
        return UIImageView(image: gifImage)
    }()
    
    private lazy var titleLable: UILabel = {
        let title = UILabel()
        let style = OEXTextStyle(weight: .semiBold, size: .xxxLarge, color : OEXStyles.shared().neutralBlackT())
        title.attributedText = style.attributedString(withText: "Congratulations!")
        return title
    }()
    
    private lazy var titleMessageLable: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        message.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        message.adjustsFontSizeToFitWidth = true
        let style = OEXMutableTextStyle(weight: .normal, size: .large, color : OEXStyles.shared().neutralBlackT())
        style.alignment = .center
        message.attributedText = style.attributedString(withText: "You just completed the first section of your course!")
        return message
    }()
    
    private lazy var celebrationMessageLabel: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        message.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        message.adjustsFontSizeToFitWidth = true
        let style = OEXMutableTextStyle(weight: .normal, size: .large, color : OEXStyles.shared().neutralBlackT())
        style.alignment = .center
        message.attributedText = style.attributedString(withText: "You earned it! Take a moment to celebrate it and share your progress")
        return message
    }()
    
    private lazy var keepGoingButton = UIButton()
    
    private lazy var buttonView = UIView()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.7)
        setupView()
        setupContraints()
    }
    
    func setupView() {
        modalView.backgroundColor = UIColor.white
        modalView.layer.cornerRadius = 10.0
        let jeremyGif = UIImage.gifImageWithName("CelebrateClaps")
        let imageView = UIImageView(image: jeremyGif)
        imageView.frame = CGRect(x: 20.0, y: 50.0, width: self.view.frame.size.width - 40, height: 150.0)
        clappingImage = imageView
        //modalView.addSubview(imageView)

        
        keepGoingButton.backgroundColor = OEXStyles.shared().primaryBaseColor()
        keepGoingButton.layer.cornerRadius = 20.0
        let buttonStyle = OEXMutableTextStyle(weight: .semiBold, size: .small, color: OEXStyles.shared().neutralWhiteT())
        keepGoingButton.setAttributedTitle(buttonStyle.attributedString(withText: "Keep going"), for: UIControl.State())
        keepGoingButton.oex_addAction({ [weak self] _ in
            self?.dismiss(animated: false, completion: nil)
        }, for: .touchUpInside)
        
        buttonView.backgroundColor = UIColor.gray
        
        addViews()
    }
    
    private func addViews() {
        modalView.addSubview(titleLable)
        modalView.addSubview(titleMessageLable)
        modalView.addSubview(congratulationImageView)
        modalView.addSubview(celebrationMessageLabel)
        modalView.addSubview(buttonView)
        modalView.addSubview(keepGoingButton)
        
        view.addSubview(modalView)
    }
    
    func setupContraints() {
        modalView.snp.makeConstraints { (make) in
            make.leading.equalTo(view).offset(20)
            make.trailing.equalTo(view).inset(20)
            make.top.equalTo(view).offset((view.frame.size.height/4)/2.2)
            make.bottom.equalTo(view).offset(-(view.frame.size.height/4)/2.2)
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        }
        
        titleLable.snp.makeConstraints { (make) in
            make.top.equalTo(modalView).offset(20)
            make.centerX.equalTo(modalView)
            make.height.equalTo(30)
        }
        
        titleMessageLable.snp.makeConstraints { (make) in
            make.top.equalTo(titleLable.snp.bottom).offset(30)
            make.leading.equalTo(modalView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(modalView).inset(StandardHorizontalMargin)
        }
        
        congratulationImageView.snp.makeConstraints { (make) in
            make.top.equalTo(titleMessageLable).offset(50)
            make.leading.equalTo(modalView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(modalView).inset(StandardHorizontalMargin)
            //make.height.equalTo((view.frame.size.height/3.5))
            make.height.equalTo(281)
        }
        
        celebrationMessageLabel.snp.makeConstraints { (make) in
            make.top.equalTo(congratulationImageView.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(modalView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(modalView).inset(StandardHorizontalMargin)
            make.height.equalTo(40)
        }

        buttonView.snp.makeConstraints { (make) in
            make.top.equalTo(celebrationMessageLabel.snp.bottom).offset(StandardVerticalMargin)
//            make.bottom.equalTo(keepGoingButton.snp.top).offset(StandardVerticalMargin*2)
            make.leading.equalTo(modalView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(modalView).inset(StandardHorizontalMargin)
            make.height.equalTo(40)
        }
        
        keepGoingButton.snp.makeConstraints { (make) in
            make.top.equalTo(buttonView.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(modalView).inset(20)
            make.centerX.equalTo(modalView)
            make.width.equalTo(StandardHorizontalMargin * 8)
            make.height.equalTo(30)
        }
        
//        clappingImage?.snp.makeConstraints({ (make) in
//            make.edges.equalTo(modalView)
//        })
        
    }
}
