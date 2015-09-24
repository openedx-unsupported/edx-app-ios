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
    func fetchImage(completion: (remoteImage : RemoteImage, error: NSError?) -> ()) //TODO: use result instead
}


private let imageCache = NSCache()

struct RemoteImageImpl: RemoteImage {
    let placeholder: UIImage?
    let url: String
    var localImage: UIImage?
    
    init(url: String, placeholder: UIImage?) {
        self.url = url
        self.placeholder = placeholder
    }
    
    private var filename: String {
        return (url as NSString).lastPathComponent
    }
    
    private var localFile: String {
        let cachesDir = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        let remoteImageDir = (cachesDir as NSString).stringByAppendingPathComponent("remoteimages")
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
    
    private func imageDeserializer(response: NSHTTPURLResponse, data: NSData) -> Result<UIImage> {
        return UIImage(data: data).toResult()
    }
    
    func fetchImage(completion: (remoteImage: RemoteImage, error: NSError?) -> ()) {
        let request = NetworkRequest(method: .GET,
            path: url,
            requiresAuth: true,
            deserializer: .DataResponse(imageDeserializer)
        )
        let task = OEXRouter.sharedRouter().environment.networkManager.taskForRequest(request) { result in
            var newImage = self
            if let image = result.data {
                newImage.localImage = image
                newImage.saveImage()
            } //TODO:
            dispatch_async(dispatch_get_main_queue()) {  completion(remoteImage: newImage, error: nil) } //TODO:
        }
    }
    
    private func saveImage() {
        guard let im = localImage else { return }

        let cost = Int(im.size.height * im.size.width)
        imageCache.setObject(im, forKey: filename, cost: cost)
        
//        im.dat TODO
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
//    mutating 
    func fetchImage(completion: (remoteImage : RemoteImage, error: NSError?) -> ()) {
        dispatch_async(dispatch_get_main_queue()) { completion(remoteImage: self, error: nil) }
    }
}

//TODO: cancel exsisting remote images
private let riTag = -2000
extension UIImageView {
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
            ri.fetchImage(self.handleRemoteLoaded)
        }
    }
    
    func handleRemoteLoaded(remoteImage : RemoteImage, error: NSError?) {
        self.stopSpinner()
        if error != nil {
            image = remoteImage.brokenImage
        } else {
            image = remoteImage.image
        }
    }
    
    func startSpinner() {
        let sv = SpinnerView(size: .Large, color: .Primary)
        sv.tag = riTag
        superview?.addSubview(sv)
        sv.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(snp_center)
        }
        sv.startAnimating()
        sv.hidden = false
    }
    
    func stopSpinner() {
        guard let spinner = superview?.viewWithTag(riTag) as? SpinnerView else { return }
        spinner.stopAnimating()
        spinner.removeFromSuperview()
    }
}