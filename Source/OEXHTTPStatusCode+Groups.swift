//
//  OEXHTTPStatusCode+Groups.swift
//  edX
//
//  Created by Akiva Leffert on 8/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

enum HttpErrorGroup {
    case Http4xx
    case Http5xx
}

extension OEXHTTPStatusCode {
    private func isGroup(group : Int) -> Bool {
        let raw = self.rawValue
        return raw >= group * 100 && raw < (group + 1) * 100
    }
    
    var is2xx : Bool {
        return isGroup(2)
    }
    
    var is4xx : Bool {
        return isGroup(4)
    }
    
    var is5xx : Bool {
        return isGroup(5)
    }
    
    var errorGroup : HttpErrorGroup? {
        if is4xx {
            return .Http4xx
        }
        else if is5xx {
            return .Http5xx
        }
        return nil
    }
}
