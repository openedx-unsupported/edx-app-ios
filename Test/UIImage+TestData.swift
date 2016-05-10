//
//  UIImage+TestData.swift
//  edX
//
//  Created by Akiva Leffert on 4/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

private class ClassInTestBundle {}

extension UIImage {
    convenience init?(testImageNamed name: String) {
        if let path = NSBundle(forClass: ClassInTestBundle.self).pathForResource(name, ofType: "png") {
            self.init(contentsOfFile: path)
        }
        else {
            self.init()
            return nil
        }
    }
}