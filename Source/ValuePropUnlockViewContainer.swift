//
//  ValuePropUnlockViewContainer.swift
//  edX
//
//  Created by Muhammad Umer on 13/01/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class ValuePropUnlockViewContainer: NSObject {
    static let shared = ValuePropUnlockViewContainer()
    
    private let delay: TimeInterval = 2
    private var container: UIView?
    private(set) var shouldDismiss: Observable<Bool> = Observable(false)
    
    private override init() { }
    
    func showView() {
        guard let window = UIApplication.shared.window else { return }
        
        let controller = ValuePropUnlockViewController()
        controller.view.frame = window.bounds
        window.addSubview(controller.view)
        container = controller.view
        
        perform(#selector(finishTimer), with: nil, afterDelay: delay)
    }
    
    @objc func finishTimer() {
        shouldDismiss.value = true
    }
    
    func removeView(completion: (()-> ())? = nil) {
        func dismiss() {
            container?.subviews.forEach { $0.removeFromSuperview() }
            container?.removeFromSuperview()
            shouldDismiss.unsubscribe(observer: self)
            completion?()
        }
        
        if !shouldDismiss.value {
            shouldDismiss.subscribe(observer: self) { newValue, _ in
                dismiss()
            }
        } else {
            dismiss()
        }
    }
}

class ValuePropUnlockViewController: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubview()
    }
    
    private func addSubview() {
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        view.accessibilityIdentifier = "ValuePropUnlockViewController:view"
        
        let indicator = UIActivityIndicatorView()
        indicator.accessibilityIdentifier = "ValuePropUnlockViewController:activity-indicator"
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        indicator.color = OEXStyles.shared().neutralBlack()
        
        let label = UILabel()
        label.accessibilityIdentifier = "ValuePropUnlockViewController:label"
        label.numberOfLines = 0
        let textStyle = OEXMutableTextStyle(weight: .bold, size: .xxLarge, color: OEXStyles.shared().neutralXXDark())
        label.attributedText = textStyle.attributedString(withText: Strings.ValueProp.unlockingCourseAccess).setLineSpacing(1.1, alignment: .center)
        
        let container = UIView()
        container.accessibilityIdentifier = "ValuePropUnlockViewController:container"
        container.addSubview(indicator)
        container.addSubview(label)
        
        view.addSubview(container)
        
        indicator.snp.makeConstraints { make in
            make.top.equalTo(container)
            make.centerX.equalTo(container)
        }
        
        label.snp.makeConstraints { make in
            make.top.equalTo(indicator.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin)
            make.centerX.equalTo(container)
        }
        
        container.snp.makeConstraints { make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.center.equalTo(view)
        }
    }
}
