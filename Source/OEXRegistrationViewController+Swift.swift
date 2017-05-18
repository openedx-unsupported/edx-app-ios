//
//  OEXRegistrationViewController+Swift.swift
//  edX
//
//  Created by Danial Zahid on 9/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension OEXRegistrationViewController {
    
    func getRegistrationFormDescription(success: @escaping (_ response: OEXRegistrationDescription) -> ()) {
        let networkManager = self.environment.networkManager
        let networkRequest = RegistrationFormAPI.registrationFormRequest()
        
        self.stream = networkManager.streamForRequest(networkRequest)
        (self.stream as! OEXStream<OEXRegistrationDescription>).listen(self) {[weak self] (result) in
            if let data = result.value {
                self?.loadController.state = .Loaded
                success(data)
            }
            else{
                self?.loadController.state = LoadState.failed(error: result.error)
            }
        }
    }
    
    //Testing only
    public var t_loaded : OEXStream<()> {
        return (self.stream as! OEXStream<OEXRegistrationDescription>).map {_ in () }
    }
    
}
