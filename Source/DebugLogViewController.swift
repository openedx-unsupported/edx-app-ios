//
//  DebugLogViewController.swift
//  edX
//
//  Created by Michael Katz on 11/19/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class DebugLogViewController : UIViewController {
    var textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.editable = false

        self.view = textView

        loadLog()

        let shareButton = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share")
        let clearButton = UIBarButtonItem(barButtonSystemItem: .Trash, target: self, action: "clear")
        navigationItem.rightBarButtonItems = [clearButton, shareButton]
    }

    private func loadLog() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            if let textData = NSData(contentsOfFile: DebugMenuLogger.instance.filename) {
                let text = String(data: textData, encoding:  NSUTF8StringEncoding)
                dispatch_async(dispatch_get_main_queue()) {
                    self.textView.text = text
                }
            }
        }
    }

    func share() {
        let c = UIActivityViewController(activityItems: [self.textView.text], applicationActivities: nil)
        presentViewController(c, animated: true, completion: nil)
    }

    func clear() {
        DebugMenuLogger.instance.clear()
        loadLog()
    }
}