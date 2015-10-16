//
//  RemoteImage.swift
//  edX
//
//  Created by Michael Katz on 9/24/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

protocol RemoteImage {
    var placeholder: UIImage? { get }
    var brokenImage: UIImage? { get }
    var image: UIImage? { get }
    
    /** Callback should be on main thread */
    func fetchImage(completion: (remoteImage : NetworkResult<RemoteImage>) -> ()) -> Removable
}


private let imageCache = NSCache()

struct RemoteImageImpl: RemoteImage {
    let placeholder: UIImage?
    let url: String
    var localImage: UIImage?
    let networkManager: NetworkManager
    
    init(url: String, networkManager: NetworkManager, placeholder: UIImage?) {
        self.url = url
        self.placeholder = placeholder
        self.networkManager = networkManager
    }
    
    private var filename: String {
        return (url as NSString).lastPathComponent
    }
    
    private var localFile: String {
        let cachesDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        let remoteImageDir = (cachesDir as NSString).stringByAppendingPathComponent("remoteimages")
        if !NSFileManager.defaultManager().fileExistsAtPath(remoteImageDir) {
            _ = try? NSFileManager.defaultManager().createDirectoryAtPath(remoteImageDir, withIntermediateDirectories: true, attributes: nil)
        }
        return (remoteImageDir as NSString).stringByAppendingPathComponent(filename)
    }
    
    var image: UIImage? {
        if localImage != nil { return localImage }
        
        if let cachedImage = imageCache.objectForKey(filename) {
            return cachedImage as? UIImage
        }
        
        if let localImage = UIImage(contentsOfFile: localFile) {
            let cost = Int(localImage.size.height * localImage.size.width)
            imageCache.setObject(localImage, forKey: filename, cost: cost) //?
        }
        
        return nil
    }
    
    private func imageDeserializer(response: NSHTTPURLResponse, data: NSData) -> Result<RemoteImage> {
        if let newImage = UIImage(data: data) {
            var result = self
            result.localImage = newImage
            
            let cost = data.length
            imageCache.setObject(newImage, forKey: filename, cost: cost)
            
            data.writeToFile(localFile, atomically: false)
            return Success(result)
        }
        
        return Failure(NSError.oex_unknownError())
    }
    
    func fetchImage(completion: (remoteImage : NetworkResult<RemoteImage>) -> ()) -> Removable {
        let request = NetworkRequest(method: .GET,
            path: url,
            requiresAuth: true,
            deserializer: .DataResponse(imageDeserializer)
        )
        return networkManager.taskForRequest(request, handler: completion)
    }
}

private struct RemoteImageJustImage : RemoteImage {
    let placeholder: UIImage?
    var image: UIImage?
    
    init (image: UIImage?) {
        self.image = image
        self.placeholder = image
    }
}

extension RemoteImage {
    var brokenImage:UIImage? { return placeholder }
    func fetchImage(completion: (remoteImage : NetworkResult<RemoteImage>) -> ()) -> Removable {
        let result = NetworkResult<RemoteImage>(request: nil, response: nil, data: self, baseData: nil, error: nil)
        completion(remoteImage: result)
        return BlockRemovable {}
    }
}

extension UIImageView {
    private struct AssociatedKeys {
        static var SpinerName = "remoteimagespinner"
        static var LastRemoteTask = "lastremotetask"
    }
    
    var spinner: SpinnerView? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.SpinerName) as? SpinnerView
        }
        set {
            if let oldSpinner = objc_getAssociatedObject(self, &AssociatedKeys.SpinerName) as? SpinnerView {
                oldSpinner.removeFromSuperview()
            }
            if newValue != nil {
                objc_setAssociatedObject(self, &AssociatedKeys.SpinerName, newValue, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    var lastRemoteTask: Removable? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.LastRemoteTask) as? Removable
        }
        set {
            if let oldTask = objc_getAssociatedObject(self, &AssociatedKeys.LastRemoteTask) as? Removable {
                oldTask.remove()
            }
            if let newTask = newValue as? AnyObject {
                objc_setAssociatedObject(self, &AssociatedKeys.LastRemoteTask, newTask, .OBJC_ASSOCIATION_RETAIN)
            }
        }
    }
    
    var remoteImage: RemoteImage? {
        get { return RemoteImageJustImage(image: image) }
        set {
            guard let ri = newValue else { image = nil; return }
            
            let localImage = ri.image
            if localImage != nil {
                image = localImage
                return
            }
            
            image = ri.placeholder
            
            startSpinner()
            lastRemoteTask = ri.fetchImage(self.handleRemoteLoaded)
        }
    }
    
    func handleRemoteLoaded(result : NetworkResult<RemoteImage>) {
        self.stopSpinner()
        
        if let remoteImage = result.data {
            if let im = remoteImage.image {
                image = im
            } else {
                image = remoteImage.brokenImage
            }
        }
    }
    
    func startSpinner() {
        if spinner == nil {
            spinner = SpinnerView(size: .Large, color: .Primary)
        }
        
        superview?.addSubview(spinner!)
        spinner!.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(snp_center)
        }
        spinner!.startAnimating()
        spinner!.hidden = false
    }
    
    func stopSpinner() {
        spinner?.stopAnimating()
        spinner?.removeFromSuperview()
    }
}