//
//  ValuePropDetailViewController.swift
//  edX
//
//  Created by Salman on 19/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

enum ValuePropModalType {
    case courseEnrollment
    case courseUnit
}

class ValuePropDetailViewController: UIViewController, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXStylesProvider
    
    private lazy var valuePropTableView = ValuePropTableView()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = titleStyle.attributedString(withText: Strings.ValueProp.upgrade(courseName: course.name ?? ""))
        return label
    }()
    
    private lazy var buttonUpgradeNow = ValuePropUpgradeButtonView()
    
    private var titleStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .xxLarge, color: OEXStyles.shared().primaryBaseColor())
        style.alignment = .left
        return style
    }()
    
    private let crossButtonSize: CGFloat = 20
        
    private var type: ValuePropModalType
    private let course: OEXCourse
    private let environment: Environment
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = environment.styles.standardBackgroundColor()
        configureView()
    }
    
    init(type: ValuePropModalType, course: OEXCourse, environment: Environment) {
        self.type = type
        self.course = course
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        addSubviews()
        setConstraints()
    }
    
    private func addSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(valuePropTableView)
        view.addSubview(buttonUpgradeNow)
        addCloseButton()
    }
    
    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: crossButtonSize), style: .plain, target: nil, action: nil)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "ValuePropDetailView:close-button"
        navigationItem.rightBarButtonItem = closeButton
        
        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func setConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(view).inset(StandardHorizontalMargin * 2)
            make.top.equalTo(view).offset(StandardVerticalMargin * 2)
        }
        
        valuePropTableView.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(StandardHorizontalMargin * 1.5)
            make.trailing.equalTo(view).inset(StandardHorizontalMargin * 2)
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(buttonUpgradeNow.snp.top).inset(StandardVerticalMargin)
        }
        
        buttonUpgradeNow.snp.makeConstraints { make in
            make.leading.equalTo(view).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(view).inset(StandardHorizontalMargin * 2)
            make.bottom.equalTo(safeBottom).inset(StandardVerticalMargin)
            make.height.equalTo(ValuePropUpgradeButtonView.height)
        }
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
}
