//
//  ChatAttachmentViewController.swift
//  PreMedical
//
//  Created by macbook on 4/5/20.
//  Copyright © 2020 Medical Call. All rights reserved.
//

import UIKit
import ActionSheetPicker_3_0
import MobileCoreServices
import AVFoundation
struct FileData {
    let data: Data
    let name: String
}

protocol ChatAttachmentViewControllerDelegate: class {
    func returnWith(file: FileData, type: String)
}
protocol ChatAttechedVideoBigger:class {
    func showVideoAlert()
}
class ChatAttachmentViewController: UIViewController {
    weak var delegate: ChatAttachmentViewControllerDelegate?
    weak var videoDelegate: ChatAttechedVideoBigger?
    let imagepicker = UIImagePickerController()
    private var session = AVAudioSession.sharedInstance()

    @IBAction func dismissView(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pickFile(_ sender: UIButton) {
        attachDocument()
    }
    
    @IBAction func pickPhoto(_ sender: UIButton) {
        let choiceArr = ["camera","gallary"]
        let acp = ActionSheetMultipleStringPicker(title: "choiceimg", rows: [choiceArr], initialSelection: [1, 1], doneBlock: {
            picker, values, indexes in
            let index = indexes as! Array<Any>
            if (index[0] as? String) == "camera" {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    self.imagepicker.delegate = self
                    self.imagepicker.allowsEditing = true
                    self.imagepicker.sourceType = .camera
                    self.imagepicker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeImage as String]
                    self.imagepicker.modalPresentationStyle = .fullScreen
                    self.present(self.imagepicker,animated: true,completion: nil)
                } else {
                    Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.noCamera), userInfo: nil, repeats: false)
                }
            }else{
                self.imagepicker.delegate = self
                self.imagepicker.allowsEditing = true
                self.imagepicker.sourceType = .photoLibrary
                self.imagepicker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeImage as String]
                self.present(self.imagepicker, animated: true, completion: nil)
            }
            
            return
        }, cancel: { ActionMultipleStringCancelBlock in return }, origin: sender)
        acp?.setDoneButton(UIBarButtonItem(title: "done", style: .done, target: nil, action: nil))
        acp?.setCancelButton(UIBarButtonItem(title: "cancel", style: .plain, target: nil, action: nil))
        acp?.tapDismissAction = TapAction.cancel
        acp?.show()
    }
}

extension ChatAttachmentViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @objc func noCamera(){
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let imageUrl = info[.imageURL] as? URL {
            let imageName = imageUrl.lastPathComponent
            guard let pickedImage = info[.originalImage] as? UIImage else {return}
            guard let data = pickedImage.jpegData(compressionQuality: 0.5) else {return}
            let fileData = FileData(data: data, name: imageName)
            picker.dismiss(animated: true) {
                self.dismiss(animated: false) {
                    self.delegate?.returnWith(file: fileData, type: "image")
                }
            }
        }
        
        if let pickedImage = info[.originalImage] as? UIImage {
            guard let data = pickedImage.jpegData(compressionQuality: 0.5) else {return}
            let fileData = FileData(data: data, name: "image\(String.randomString(length: 20)).jpeg")
            picker.dismiss(animated: true) {
                self.dismiss(animated: false) {
                    self.delegate?.returnWith(file: fileData, type: "image")
                }
            }
        }
        
        if let mediaURL = info[.mediaURL] as? URL {
            let mediaName = mediaURL.lastPathComponent
            guard let data = try? Data(contentsOf: mediaURL) else {return}
            let fileData = FileData(data: data, name: mediaName)
            picker.dismiss(animated: true) {
                self.dismiss(animated: false) {
                    let asset = AVURLAsset(url: mediaURL)
                    let durationInSeconds = asset.duration.seconds
                    if durationInSeconds > 10.0 {
                        self.videoDelegate?.showVideoAlert()
                    }else{
                        self.delegate?.returnWith(file: fileData, type: "video")
                    }
                }
            }
        }
    }
}
extension ChatAttachmentViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let myURL = urls.first else {return}
        let size = sizePerMB(url: myURL)
        if size > 1.0{
            let alert = UIAlertController(title: "Alert", message: "File is bigger than 1 MB", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "ok", style: UIAlertAction.Style.cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        let fileName = myURL.lastPathComponent
        let data = try! Data(contentsOf: myURL)
        let fileData = FileData(data: data, name: fileName)
        dismiss(animated: false) {
            self.delegate?.returnWith(file: fileData, type: "file")
        }
    }
    func sizePerMB(url: URL?) -> Double {
        guard let filePath = url?.path else {
            return 0.0
        }
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: filePath)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                return size.doubleValue / 1000000.0
            }
        } catch {
            print("Error: \(error)")
        }
        return 0.0
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    private func attachDocument() {
        let types = [kUTTypePDF, kUTTypeText, kUTTypeSpreadsheet]
        let importMenu = UIDocumentPickerViewController(documentTypes: types as [String], in: .import)
        importMenu.allowsMultipleSelection = true
        if #available(iOS 13.0, *) {
            importMenu.shouldShowFileExtensions = true
        }
        importMenu.delegate = self
        present(importMenu, animated: true)
    }
}
