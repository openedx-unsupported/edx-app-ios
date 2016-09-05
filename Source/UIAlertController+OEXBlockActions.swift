//
//  UIAlertController+OEXBlockActions.swift
//  edX
//
//  Created by Danial Zahid on 8/30/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

private let UIAlertControllerBlocksCancelButtonIndex = 0
private let UIAlertControllerBlocksDestructiveButtonIndex = 1
private let UIAlertControllerBlocksFirstOtherButtonIndex = 2

extension UIAlertController {
    
    //MARK:- Init Methods
    
    func showInViewController(viewController: UIViewController,
                              title: String?,
                              message: String?,
                              preferredStyle: UIAlertControllerStyle,
                              cancelButtonTitle: String?,
                              destructiveButtonTitle: String?,
                              otherButtonsTitle: [String]?,
                              tapBlock: ((controller: UIAlertController, action: UIAlertAction, buttonIndex: Int) -> ())?) -> UIAlertController{
        
        let controller = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        
        if let cancelText = cancelButtonTitle {
            let cancelAction = UIAlertAction(title: cancelText, style: UIAlertActionStyle.Cancel, handler: { (action) in
                if let tap = tapBlock {
                    tap(controller: controller, action: action, buttonIndex: UIAlertControllerBlocksCancelButtonIndex)
                }
            })
            controller.addAction(cancelAction)
        }
        
        if let destructiveText = destructiveButtonTitle {
            let destructiveAction = UIAlertAction(title: destructiveText, style: UIAlertActionStyle.Destructive, handler: { (action) in
                if let tap = tapBlock {
                    tap(controller: controller, action: action, buttonIndex: UIAlertControllerBlocksDestructiveButtonIndex)
                }
            })
            controller.addAction(destructiveAction)
        }
        
        if let otherButtonsText = otherButtonsTitle {
            for otherTitle in otherButtonsText {
                let otherAction = UIAlertAction(title: otherTitle, style: UIAlertActionStyle.Default, handler: { (action) in
                    if let tap = tapBlock {
                        tap(controller: controller, action: action, buttonIndex: UIAlertControllerBlocksDestructiveButtonIndex)
                    }
                })
                controller.addAction(otherAction)
            }
        }
        
        viewController.presentViewController(controller, animated: true, completion: nil)
        
        return controller
        
    }
    
    func showAlertWithTitle(title: String?,
                            message: String?,
                            cancelButtonTitle: String?,
                            onViewController viewController: UIViewController) -> UIAlertController{

        return self.showInViewController(viewController,
                                         title: title,
                                         message: message,
                                         preferredStyle: UIAlertControllerStyle.Alert,
                                         cancelButtonTitle: cancelButtonTitle,
                                         destructiveButtonTitle: nil,
                                         otherButtonsTitle: nil,
                                         tapBlock: nil)
        
    }
    
    func showAlertWithTitle(title: String?,
                            message: String?,
                            onViewController viewController: UIViewController) -> UIAlertController{
        
        return self.showAlertWithTitle(title,
                                       message: message,
                                       cancelButtonTitle: OEXLocalizedString("OK", nil),
                                       onViewController: viewController)
        
    }
    
    //MARK:- Add Action Methods
    
    func addActionButtonWithTitle(title: String,
                                  style: UIAlertActionStyle,
                                  actionBlock: ((action: UIAlertAction) -> ())?) {
        
        let alertAction = UIAlertAction(title: title, style: style, handler: { (action) in
            if let tap = actionBlock {
                tap(action: action)
            }
        })
        self.addAction(alertAction)
        
    }
    
    //MARK:- Helper Variables
    
    var visible : Bool {
        return self.view.superview != nil;
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