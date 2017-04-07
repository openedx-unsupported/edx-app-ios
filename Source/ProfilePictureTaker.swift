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
    func imagePicked(image: UIImage, picker: UIImagePickerController)
    func cancelPicker(picker: UIImagePickerController)
    func deleteImage()
}


class ProfilePictureTaker : NSObject {
    
    weak var delegate: ProfilePictureTakerDelegate?
    
    init(delegate: ProfilePictureTakerDelegate) {
        self.delegate = delegate
    }
    
    func start(alreadyHasImage: Bool) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let action = UIAlertAction(title: Strings.Profile.takePicture, style: .default) { _ in
                self.showImagePicker(sourceType: .camera)
            }
            alert.addAction(action)
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let action = UIAlertAction(title: Strings.Profile.chooseExisting, style: .default) { _ in
                self.showImagePicker(sourceType: .photoLibrary)
            }
            alert.addAction(action)
        }
        if alreadyHasImage {
            let action = UIAlertAction(title: Strings.Profile.removeImage, style: .destructive) { _ in
                self.delegate?.deleteImage()
            }
            alert.addAction(action)
        }
        alert.addCancelAction()
        delegate?.showChooserAlert(alert: alert)
        
    }
    
 
    private func showImagePicker(sourceType : UIImagePickerControllerSourceType) {
        
        let imagePicker = UIImagePickerController()
        let mediaType: String = kUTTypeImage as String
        imagePicker.mediaTypes = [mediaType]
        imagePicker.sourceType = sourceType
        imagePicker.delegate = self
        
        if sourceType == .camera {
            imagePicker.showsCameraControls = true
            imagePicker.cameraCaptureMode = .photo
            imagePicker.cameraDevice = .front
            imagePicker.cameraFlashMode = .auto
        }
        self.delegate?.showImagePickerController(picker: imagePicker)
    }
    
}


extension ProfilePictureTaker : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let rotatedImage = image.rotateUp()
            let cropper = CropViewController(image: rotatedImage) { [weak self] maybeImage in
                if let newImage = maybeImage {
                    self?.delegate?.imagePicked(image: newImage, picker: picker)
                } else {
                    self?.delegate?.cancelPicker(picker: picker)
                }
            }
            picker.pushViewController(cropper, animated: true)
        } else {
            fatalError("no image returned from picker")
        }
    }
    
}
