//
//  OEXHTTPStatusCode+Groups.swift
//  edX
//
//  Created by Akiva Leffert on 8/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public enum HttpErrorGroup {
    case http4xx
    case http5xx
}

public extension OEXHTTPStatusCode {
    fileprivate func isGroup(_ group : Int) -> Bool {
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
    
    public var errorGroup : HttpErrorGroup? {
        if is4xx {
            return .http4xx
        }
        else if is5xx {
            return .http5xx
        }
        return nil
    }
    
}
