//
//  UIAlertController+OEXBlockActions.swift
//  edX
//
//  Created by Danial Zahid on 8/30/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

let UIAlertControllerBlocksCancelButtonIndex = 0
private let UIAlertControllerBlocksDestructiveButtonIndex = 1
private let UIAlertControllerBlocksFirstOtherButtonIndex = 2

extension UIAlertController {
    
    //MARK:- Init Methods
    
    @objc @discardableResult func showAlert(with title: String?,
                                   message: String?,
                                   preferredStyle: UIAlertController.Style,
                                   cancelButtonTitle: String?,
                                   destructiveButtonTitle: String?,
                                   otherButtonsTitle: [String]?,
                                   tapBlock: ((_ controller: UIAlertController, _ action: UIAlertAction, _ buttonIndex: Int) -> ())?, textFieldWithConfigurationHandler: ((_ textField: UITextField) -> Void)? = nil) -> UIAlertController?{
        
        guard let controller = UIApplication.shared.topMostController() else { return nil }
        
        return showIn(viewController: controller, title: title, message: message, preferredStyle: preferredStyle, cancelButtonTitle: cancelButtonTitle, destructiveButtonTitle: destructiveButtonTitle, otherButtonsTitle: otherButtonsTitle, tapBlock: tapBlock)
    }
    
    
    @objc @discardableResult func showIn(viewController pController: UIViewController,
                                   title: String?,
                                   message: String?,
                                   preferredStyle: UIAlertController.Style,
                                   cancelButtonTitle: String?,
                                   destructiveButtonTitle: String?,
                                   otherButtonsTitle: [String]?,
                                   tapBlock: ((_ controller: UIAlertController, _ action: UIAlertAction, _ buttonIndex: Int) -> ())?, textFieldWithConfigurationHandler: ((_ textField: UITextField) -> Void)? = nil) -> UIAlertController{
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        
        if let textFieldHandler = textFieldWithConfigurationHandler {
            controller.addTextField() { textField in
                textFieldHandler(textField)
            }
        }
        
        if let cancelText = cancelButtonTitle {
            let cancelAction = UIAlertAction(title: cancelText, style: UIAlertAction.Style.cancel, handler: { (action) in
                if let tap = tapBlock {
                    tap(controller, action, UIAlertControllerBlocksCancelButtonIndex)
                }
            })
            controller.addAction(cancelAction)
        }
        
        if let destructiveText = destructiveButtonTitle {
            let destructiveAction = UIAlertAction(title: destructiveText, style: UIAlertAction.Style.destructive, handler: { (action) in
                if let tap = tapBlock {
                    tap(controller, action, UIAlertControllerBlocksDestructiveButtonIndex)
                }
            })
            controller.addAction(destructiveAction)
        }
        
        if let otherButtonsText = otherButtonsTitle {
            for otherTitle in otherButtonsText {
                let otherAction = UIAlertAction(title: otherTitle, style: UIAlertAction.Style.default, handler: { (action) in
                    if let tap = tapBlock {
                        tap(controller, action, UIAlertControllerBlocksDestructiveButtonIndex)
                    }
                })
                controller.addAction(otherAction)
            }
        }
        
        pController.present(controller, animated: true, completion: nil)
        
        return controller
        
    }
    @objc @discardableResult func showAlert(withTitle title: String?,
                                      message: String?,
                                      cancelButtonTitle: String?,
                                      onViewController viewController: UIViewController) -> UIAlertController{
        
        return self.showIn(viewController: viewController,
                           title: title,
                           message: message,
                           preferredStyle: UIAlertController.Style.alert,
                           cancelButtonTitle: cancelButtonTitle,
                           destructiveButtonTitle: nil,
                           otherButtonsTitle: nil,
                           tapBlock: nil)
        
    }
    
    @objc @discardableResult func showAlert(withTitle title: String?,
                                      message: String?,
                                      onViewController viewController: UIViewController) -> UIAlertController{
        
        return self.showAlert(withTitle: title,
                              message: message,
                              cancelButtonTitle: Strings.ok,
                              onViewController: viewController)
        
    }
    
    @objc @discardableResult func showAlert(withTitle title: String?,
                                      message: String?,
                                      cancelButtonTitle: String?,
                                      onViewController viewController: UIViewController,
                                      tapBlock:((_ controller: UIAlertController, _ action: UIAlertAction, _ buttonIndex: Int) -> ())?) -> UIAlertController{
        
        return showIn(viewController: viewController,
                      title: title,
                      message: message,
                      preferredStyle: UIAlertController.Style.alert,
                      cancelButtonTitle: cancelButtonTitle,
                      destructiveButtonTitle: nil,
                      otherButtonsTitle: nil,
                      tapBlock: tapBlock)
        
    }
    
    //MARK:- Add Action Methods
    
    func addButton(withTitle title: String,
                   style: UIAlertAction.Style,
                   actionBlock: ((_ action: UIAlertAction) -> ())?) {
        let alertAction = UIAlertAction(title: title, style: style, handler: { (action) in
            if let tap = actionBlock {
                tap(action)
            }
        })
        self.addAction(alertAction)
    }
    
    @objc func addButton(withTitle title: String,
                   actionBlock: ((_ action: UIAlertAction) -> ())?) {
        let alertAction = UIAlertAction(title: title, style: UIAlertAction.Style.default, handler: { (action) in
            if let tap = actionBlock {
                tap(action)
            }
        })
        self.addAction(alertAction)
    }
    
    //MARK:- Helper Variables
    
    var visible : Bool {
        return self.view != nil;
    }
    
    var cancelButtonIndex : Int {
        return UIAlertControllerBlocksCancelButtonIndex;
    }
    
    var firstOtherButtonIndex : Int {
        return UIAlertControllerBlocksFirstOtherButtonIndex;
    }
    
    var destructiveButtonIndex : Int{
        return UIAlertControllerBlocksDestructiveButtonIndex;
    }
    
}

extension UIAlertController {
    convenience init(style: UIAlertController.Style, childController: UIViewController, title: String? = nil, message: String? = nil) {
        self.init(title: title, message: message, preferredStyle: style)
        setValue(childController, forKey: "contentViewController")
    }
}
