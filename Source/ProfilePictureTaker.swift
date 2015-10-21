//
//  ProfilePictureTaker.swift
//  edX
//
//  Created by Michael Katz on 10/1/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

import MobileCoreServices

protocol ProfilePictureTakerDelegate : class {
    func showImagePickerController(picker: UIImagePickerController)
    func showChooserAlert(alert: UIAlertController)
    func imagePicked(image: UIImage, picker: UIViewController)
    func deleteImage()
}


class ProfilePictureTaker : NSObject {
    
    weak var delegate: ProfilePictureTakerDelegate?
    
    init(delegate: ProfilePictureTakerDelegate) {
        self.delegate = delegate
    }
    
    func start(alreadyHasImage: Bool) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let action = UIAlertAction(title: Strings.Profile.takePicture, style: .Default) { _ in
                self.showImagePicker(.Camera)
            }
            alert.addAction(action)
        }
        if UIImagePickerController.isSourceTypeAvailable(.PhotoLibrary) {
            let action = UIAlertAction(title: Strings.Profile.chooseExisting, style: .Default) { _ in
                self.showImagePicker(.PhotoLibrary)
            }
            alert.addAction(action)
        }
        if alreadyHasImage {
            let action = UIAlertAction(title: Strings.Profile.removeImage, style: .Destructive) { _ in
                self.delegate?.deleteImage()
            }
            alert.addAction(action)
        }
        alert.addCancelAction()
        delegate?.showChooserAlert(alert)
        
    }
    
 
    private func showImagePicker(sourceType : UIImagePickerControllerSourceType) {
        
        let imagePicker = UIImagePickerController()
        let mediaType: String = kUTTypeImage as String
        imagePicker.mediaTypes = [mediaType]
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        
        if sourceType == .Camera {
            imagePicker.showsCameraControls = true
            imagePicker.cameraCaptureMode = .Photo
            imagePicker.cameraDevice = .Front
            imagePicker.cameraFlashMode = .Auto
        }
        self.delegate?.showImagePickerController(imagePicker)
    }
    
}


extension ProfilePictureTaker : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let cropper = CropViewController(image: image) { [weak self] newImage in
                self?.delegate?.imagePicked(newImage, picker: picker)
            }
            picker.pushViewController(cropper, animated: true)
        } else {
            fatalError("no image returned from picker")
        }
    }
    
}