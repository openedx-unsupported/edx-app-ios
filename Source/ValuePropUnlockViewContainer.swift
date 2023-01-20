//
//  ValuePropUnlockViewContainer.swift
//  edX
//
//  Created by Muhammad Umer on 13/01/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class ValuePropUnlockViewContainer: NSObject {
    
    private let delay: TimeInterval = 3
    private var container: UIView?
    private(set) var shouldDismiss: Observable<Bool> = Observable(false)
    
    var isVisible: Bool { return container != nil }
    
    override init() { }
    
    private var controller: ValuePropUnlockViewController?
    
    func showView() {
        guard let window = UIApplication.shared.window else { return }
        
        controller = ValuePropUnlockViewController()
        
        controller?.view.frame = window.bounds
        
        if let view = controller?.view {
            window.addSubview(view)
            container = view
        }
        
        perform(#selector(finishTimer), with: nil, afterDelay: delay)
        
        NotificationCenter.default.oex_addObserver(observer: self, name: UIDevice.orientationDidChangeNotification.rawValue) { _, observer, _ in
            switch UIDevice.current.orientation {
            case .portrait:
                observer.controller?.applyPortraitOrientation()
                break
            case .landscapeLeft, .landscapeRight:
                observer.controller?.applyLandscapeOrientation()
                break
            default:
                break
            }            
        }
    }
    
    @objc private func finishTimer() {
        shouldDismiss.value = true
    }
    
    func removeView(completion: (()-> ())? = nil) {
        func dismiss() {
            controller?.removeFromParent()
            container?.subviews.forEach { $0.removeFromSuperview() }
            container?.removeFromSuperview()
            container = nil
            controller = nil
            shouldDismiss.unsubscribe(observer: self)
            NotificationCenter.default.removeObserver(self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion?()
            }
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
    
    private lazy var unlockMessageLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "ValuePropUnlockViewController:label-unlock-message"
        label.numberOfLines = 0
        
        let textStyle = OEXMutableTextStyle(weight: .bold, size: .xxxxxLarge, color: nil)
        let attributedText = textStyle.attributedString(withText: Strings.ValueProp.unlockingCourseAccess)
        
        label.attributedText = attributedText
            .setLineSpacing(0.93, alignment: .center, lineBreakMode: .byWordWrapping)
            .applyColor(color: OEXStyles.shared().primaryXLightColor(), on: Strings.ValueProp.unlockingCourseAccessPartOne, addLineBreak: true)
            .applyColor(color: OEXStyles.shared().accentAColor(), on: Strings.ValueProp.unlockingCourseAccessPartTwo, addLineBreak: true)
            .applyColor(color: OEXStyles.shared().primaryXLightColor(), on: Strings.ValueProp.unlockingCourseAccessPartThree)
        return label
    }()
    
    private lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.accessibilityIdentifier = "ValuePropUnlockViewController:activity-indicator"
        indicator.hidesWhenStopped = true
        indicator.startAnimating()
        indicator.color = OEXStyles.shared().neutralDark()
        return indicator
    }()
    
    private lazy var imageView: UIImageView = {
        guard let image = UIImage(named: "campaign_launch") else { return UIImageView() }
        return UIImageView(image: image)
    }()
    
    private lazy var container: UIView = {
        let container = UIView()
        container.accessibilityIdentifier = "ValuePropUnlockViewController:container"
        container.addSubview(indicator)
        container.addSubview(unlockMessageLabel)
        container.addSubview(imageView)
        return container
    }()
    
    private func addSubview() {
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        view.accessibilityIdentifier = "ValuePropUnlockViewController:view"
        view.addSubview(container)
        
        container.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
        
        if isLandscape {
            applyLandscapeOrientation()
        } else {
            applyPortraitOrientation()
        }
    }
    
    func applyPortraitOrientation() {
        indicator.snp.remakeConstraints { make in
            make.top.equalTo(container).offset(StandardVerticalMargin * 14)
            make.centerX.equalTo(container)
        }
        
        unlockMessageLabel.snp.remakeConstraints { make in
            make.top.equalTo(indicator.snp.bottom).offset(StandardVerticalMargin * 4)
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin)
            make.centerX.equalTo(container)
        }
        
        imageView.snp.remakeConstraints { make in
            make.top.equalTo(unlockMessageLabel.snp.bottom).offset(StandardVerticalMargin * 5)
            make.leading.equalTo(container).offset(StandardHorizontalMargin * 3)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin * 3)
            make.centerX.equalTo(container)
            make.height.equalTo(imageView.snp.width).inset(StandardVerticalMargin * 2)
        }
    }
    
    func applyLandscapeOrientation() {
        indicator.snp.remakeConstraints { make in
            make.top.equalTo(container).offset(StandardVerticalMargin * 8)
            make.centerX.equalTo(container)
        }

        imageView.snp.remakeConstraints { make in
            make.top.equalTo(indicator.snp.bottom).offset(StandardVerticalMargin * 6)
            make.leading.equalTo(container).offset(StandardHorizontalMargin * 3)
            make.width.equalTo(UIScreen.main.bounds.width / 3)
            make.height.equalTo(imageView.snp.width)
            make.bottom.equalTo(container).inset(StandardVerticalMargin * 4)
        }

        unlockMessageLabel.snp.remakeConstraints { make in
            make.centerY.equalTo(imageView)
            make.leading.equalTo(indicator.snp.trailing).inset(StandardHorizontalMargin * 2)
            make.height.equalTo(imageView)
            make.width.equalTo(imageView)
            make.bottom.equalTo(imageView.snp.bottom)
        }
    }
}
