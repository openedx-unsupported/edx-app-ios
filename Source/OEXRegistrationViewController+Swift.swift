//
//  OEXRegistrationViewController+Swift.swift
//  edX
//
//  Created by Danial Zahid on 9/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension OEXRegistrationViewController {
    
    func registrationFormDeserializer(response : NSHTTPURLResponse, json : JSON) -> Result<OEXRegistrationDescription> {
        return json.dictionaryObject.map { OEXRegistrationDescription(dictionary: $0) }.toResult()
    }
    
    func getRegistrationFormDescription(responseBlock: (response: OEXRegistrationDescription) -> ()) {
        let networkManager = self.environment.networkManager
        let networkRequest = NetworkRequest(method: .GET, path: SIGN_UP_URL, deserializer: .JSONResponse(registrationFormDeserializer))
        
        self.stream = networkManager.streamForRequest(networkRequest)
        (self.stream as! Stream<OEXRegistrationDescription>).listen(self) { (result) in
            if let data = result.value {
                self.loadController.state = .Loaded
                responseBlock(response: data)
            }
            else{
                self.loadController.state = LoadState.failed(result.error, icon: nil, message: nil)
            }
        }
    }
    
    public var t_loaded : Stream<()> {
        return (self.stream as! Stream<OEXRegistrationDescription>).map {_ in () }
    }
    
}