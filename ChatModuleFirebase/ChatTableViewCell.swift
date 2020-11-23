//
//  ChatTableViewCell.swift
//  PreMedical
//
//  Created by macbook on 4/5/20.
//  Copyright © 2020 Medical Call. All rights reserved.
//

import UIKit

class ChatTextTableViewCell: UITableViewCell {
    @IBOutlet weak var containerViewLeading: NSLayoutConstraint!
    @IBOutlet weak var containerViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seenImageView: UIImageView!
}

class ChatImageTableViewCell: UITableViewCell {
    @IBOutlet weak var containerViewLeading: NSLayoutConstraint!
    @IBOutlet weak var containerViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seenImageView: UIImageView!
}

class ChatFileTableViewCell: UITableViewCell {
    @IBOutlet weak var containerViewLeading: NSLayoutConstraint!
    @IBOutlet weak var containerViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seenImageView: UIImageView!
}

class ChatVideoTableViewCell: UITableViewCell {
    @IBOutlet weak var containerViewLeading: NSLayoutConstraint!
    @IBOutlet weak var containerViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seenImageView: UIImageView!
}

class ChatAudioTableViewCell: UITableViewCell {
    @IBOutlet weak var containerViewLeading: NSLayoutConstraint!
    @IBOutlet weak var containerViewTrailing: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var seenImageView: UIImageView!
    
    var playButtonTapped: (() -> Void)?
    
    @IBAction func playButtonTapped(_ sender: UIButton) {
        playButtonTapped?()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        slider.setThumbImage(UIImage(named: "circle"), for: .normal)
        slider.setValue(0, animated: false)
    }
    
}
