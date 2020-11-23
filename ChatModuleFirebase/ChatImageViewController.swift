//
//  ChatImageViewController.swift
//  PreMedical
//
//  Created by macbook on 4/28/20.
//  Copyright © 2020 Medical Call. All rights reserved.
//

import UIKit
import FirebaseUI

class ChatImageViewController: UIViewController {
    @IBOutlet weak var messageImageView: UIImageView!

    var imageName: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let storageRef = Storage.storage().reference()
        let reference = storageRef.child(imageName)
        messageImageView.sd_imageTransition = .fade
        messageImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
        messageImageView.sd_setImage(with: reference)
    }
    
    @IBAction func dismiss() {
        dismiss(animated: true, completion: nil)
    }
}
