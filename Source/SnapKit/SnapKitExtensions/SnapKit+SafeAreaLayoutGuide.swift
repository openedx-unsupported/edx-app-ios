//
//  SnapKit+SafeAreaLayoutGuide.swift
//  edX
//
//  Created by Zeeshan Arif on 5/4/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

extension UIViewController {
    private typealias SafeConstraintItem = ConstraintAttributesDSL & ConstraintDSL
    private var safeConstraintItem: SafeConstraintItem {
        if #available(iOS 11, *) {
            return view.safeAreaLayoutGuide.snp
        }
        else {
            return view.snp
        }
    }
    
    var safeTop: ConstraintItem {
        return safeConstraintItem.top
    }
    
    var safeBottom: ConstraintItem {
        return safeConstraintItem.bottom
    }
    
    var safeLeading: ConstraintItem {
        return safeConstraintItem.leading
    }
    
    var safeTrailing: ConstraintItem {
        return safeConstraintItem.trailing
    }
    
    var safeEdges: ConstraintItem {
        return safeConstraintItem.edges
    }
    
}
