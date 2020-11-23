//
//  DoctorChatViewController.swift
//  PreMedical
//
//  Created by macbook on 4/4/20.
//  Copyright © 2020 Medical Call. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseUI
import AVFoundation
import AVKit
import iRecordView

class DoctorChatViewController: UIViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var messageTextField: UITextField!
  @IBOutlet weak var recordButton: RecordButton!
  @IBOutlet weak var recordView: RecordView!
  @IBOutlet weak var sendButton: UIButton!
  @IBOutlet weak var attatchmentButton: UIButton!
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  
  private enum MessageType: String {
    case image
    case text
    case audio
    case video
    case file
  }
  var chatData = [MessageData]()
  private var chatId: Int!
    private var databaseRef:DatabaseReference!
    private var storageRef : StorageReference!
  private var recordingSession: AVAudioSession!
  private var audioRecorder: AVAudioRecorder!
  private var player: AVAudioPlayer?
  private var timer: Timer?
  private var chatTimer: Timer!
  private var minuteCounter: Int!
  private var secCounter: Int!
  private var second = true
  private var session = AVAudioSession.sharedInstance()
    private var messageCounter:Int = 0
    private var user = "adel2"
  override func viewDidLoad() {
    super.viewDidLoad()
    chatId = 1
    databaseRef = Database.database().reference()
    storageRef = Storage.storage().reference()
    startChatAtSpecificTime()
    setAudioSessionAttributes()
    setAttributesAfterGetMessages()
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
  }
    
  
  private func startChatAtSpecificTime() {
    databaseRef.child("chat").child(String(chatId)).child("finished").observeSingleEvent(of: .value) { (snapshot) in
      let value = snapshot.value as? String
      if value != "1" {
//        self.recordButton.isEnabled = false
//        self.sendButton.isEnabled = false
//        self.messageTextField.isEnabled = false
//        self.attatchmentButton.isEnabled = false
      }
    }
  }
  
  @objc private func start() {
    recordButton.isEnabled = true
    self.sendButton.isEnabled = true
    messageTextField.isEnabled = true
    attatchmentButton.isEnabled = true
    let audioSession = AVAudioSession.sharedInstance()

    do {
        try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
    } catch let error as NSError {
        print("audioSession error: \(error.localizedDescription)")
    }
  }
  
  private func setAudioSessionAttributes() {
    recordingSession = AVAudioSession.sharedInstance()
    do {
      try recordingSession.setCategory(.playAndRecord, mode: .default)
      try recordingSession.setActive(true)
      recordingSession.requestRecordPermission() { allowed in
        DispatchQueue.main.async {
          if allowed {
            self.recordButton.recordView = self.recordView
            self.recordView.slideToCancelText = "slide to cancel"
            self.recordView.slideToCancelArrowImage = nil
            self.recordView.delegate = self
          } else {
            self.recordButton.isUserInteractionEnabled = false
          }
        }
      }
    } catch {
      // failed to record!
    }
  }
  
  private func setAttributesAfterGetMessages() {
    self.getMessages { (message) in
      self.chatData.append(message)
      self.tableView.reloadData()
      self.scrollToBottom()
    }
  }
  
  private func scrollToBottom(){
    DispatchQueue.main.async {
      if !self.chatData.isEmpty {
        let indexPath = IndexPath(row: self.chatData.count - 1, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
      }
    }
  }
  
  @IBAction func goBack(_ sender: UIButton) {
    navigationController?.popViewController(animated: true)
  }
  
  @IBAction func sendMessage(_ sender: UIButton) {
    if messageCounter < 5 {
        messageCounter += 1
        guard let message = messageTextField.text, !message.isEmpty else {return}
        let messageData = MessageData(apiToken: "", senderName: user, actorType: "1", seenByDoctor: "0", createdAt: Date().toString(), messageType: "text", message: message, fileName: nil, imageName: nil, audioName: nil, videoName: nil, messageNumber: "\(messageCounter)")
        sendTextWith(message: messageData)
    }else{
        sendNoMore()
    }
  }
  
  @IBAction func attachmentButtonTapped(_ sender: Any) {
    let chatAttachmentVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chatAttachmentVC") as! ChatAttachmentViewController
    chatAttachmentVC.delegate = self
    chatAttachmentVC.videoDelegate = self
    present(chatAttachmentVC, animated: true, completion: nil)
  }
}

extension DoctorChatViewController {
  private func getMessages(completionHandler: @escaping(MessageData)->()) {
    databaseRef.child("chat").child(String(chatId)).child("chat").observeSingleEvent(of: .value) { (snapshot) in
      if !snapshot.hasChildren() {return}
    }
    databaseRef.child("chat").child(String(chatId)).child("chat").observe(.childAdded) { (snapShot) in
      let values = snapShot.value as? [String: String]
      let apiToken = values?["apiToken"]
      let senderName = values?["senderName"]
      let actorType = values?["actorType"]
      let seenByDoctor = values?["seenByDoctor"]
      let createdAt = values?["createdAt"]
      let messageType = values?["messageType"]
      let message = values?["message"]
      let fileName = values?["fileName"]
      let imageName = values?["imageName"]
      let audioName = values?["audioName"]
      let videoName = values?["videoName"]
      let messageNumber = values?["messageNumber"]
        if senderName == self.user{
            if let number = messageNumber{
                let n = Int(number)!
                self.messageCounter = n
            }
        }
        let messageData = MessageData(apiToken: apiToken, senderName: senderName, actorType: actorType, seenByDoctor: seenByDoctor, createdAt: createdAt, messageType: messageType, message: message, fileName: fileName, imageName: imageName, audioName: audioName, videoName: videoName, messageNumber: messageNumber)
      completionHandler(messageData)
    }
  }
  
  private func sendTextWith(message: MessageData) {
    databaseRef.child("chat").child(String(chatId)).child("chat")
      .childByAutoId()
        .setValue(["apiToken": message.apiToken, "senderName": message.senderName, "actorType": message.actorType, "seenByDoctor": message.seenByDoctor, "createdAt": message.createdAt, "messageType": message.messageType, "message": message.message, "messageNumber":message.messageNumber])
    messageTextField.text = nil
  }
    func  sendNoMore() {
        let resourcePath = Bundle.main.resourcePath
                let stringURL = resourcePath! + "/sms-alert-3-daniel_simon.mp3" //change foo to your file name you have added in project
                let url = URL.init(fileURLWithPath: stringURL)
                player = try! AVAudioPlayer(contentsOf: url)
        guard let player = self.player else {
            return
        }
        do{
            try self.session.overrideOutputAudioPort(.speaker)
        }catch let err{
            print(err)
        }
        let alert = UIAlertController(title: "Alert", message: "you can not send more messages", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
            player.stop()
                }))
                player.play()
                self.present(alert, animated: true, completion: nil)
    }
  
  private func sendImageWith(message: MessageData, fileData: FileData, type: String) {
    if messageCounter > 5{
        sendNoMore()
        return
    }
    uploadUserImageToStorage(fileData: fileData) { (success)  in
      if success {
        switch type {
        case MessageType.image.rawValue:
          self.databaseRef.child("chat").child(String(self.chatId)).child("chat")
            .childByAutoId()
            .setValue(["apiToken": message.apiToken, "senderName": message.senderName, "actorType": message.actorType, "seenByDoctor": message.seenByDoctor, "createdAt": message.createdAt, "messageType": message.messageType, "imageName": message.imageName, "messageNumber":message.messageNumber])
          break
        case MessageType.file.rawValue:
          self.databaseRef.child("chat").child(String(self.chatId)).child("chat")
            .childByAutoId()
            .setValue(["apiToken": message.apiToken, "senderName": message.senderName, "actorType": message.actorType, "seenByDoctor": message.seenByDoctor, "createdAt": message.createdAt, "messageType": message.messageType, "fileName": message.fileName, "messageNumber":message.messageNumber])
          break
        case MessageType.audio.rawValue:
          self.databaseRef.child("chat").child(String(self.chatId)).child("chat")
            .childByAutoId()
            .setValue(["apiToken": message.apiToken, "senderName": message.senderName, "actorType": message.actorType, "seenByDoctor": message.seenByDoctor, "createdAt": message.createdAt, "messageType": message.messageType, "audioName": message.audioName, "messageNumber":message.messageNumber])
          break
        case MessageType.video.rawValue:
          self.databaseRef.child("chat").child(String(self.chatId)).child("chat")
            .childByAutoId()
            .setValue(["apiToken": message.apiToken, "senderName": message.senderName, "actorType": message.actorType, "seenByDoctor": message.seenByDoctor, "createdAt": message.createdAt, "messageType": message.messageType, "videoName": message.videoName, "messageNumber":message.messageNumber])
          break
        default:
          break
        }
      }
    }
  }
  
  private func uploadUserImageToStorage(fileData: FileData, completionHandler: @escaping(_: Bool)->()) {
    storageRef.child(fileData.name).putData(fileData.data, metadata: nil) {(metadata, error) in
      if let _ = error {
        completionHandler(false)
      } else {
        completionHandler(true)
      }
    }
  }
}

extension DoctorChatViewController: ChatAttachmentViewControllerDelegate {
  func returnWith(file: FileData, type: String) {
    switch type {
    case MessageType.image.rawValue:
        messageCounter += 1
        let messageData = MessageData(apiToken: "", senderName: user, actorType: "1", seenByDoctor: "0", createdAt: Date().toString(), messageType: type, message: nil, fileName: nil, imageName: file.name, audioName: nil, videoName: nil, messageNumber: "\(messageCounter)")
      sendImageWith(message: messageData, fileData: file, type: type)
      break
    case MessageType.file.rawValue:
        messageCounter += 1
        let messageData = MessageData(apiToken: "", senderName: user, actorType: "1", seenByDoctor: "0", createdAt: Date().toString(), messageType: type, message: nil, fileName: file.name, imageName: nil, audioName: nil, videoName: nil, messageNumber: "\(messageCounter)")
      sendImageWith(message: messageData, fileData: file, type: type)
      break
    case MessageType.video.rawValue:
        messageCounter += 1
        let messageData = MessageData(apiToken: "", senderName: user, actorType: "1", seenByDoctor: "0", createdAt: Date().toString(), messageType: type, message: nil, fileName: nil, imageName: nil, audioName: nil, videoName: file.name, messageNumber: "\(messageCounter)")
      sendImageWith(message: messageData, fileData: file, type: type)
      break
    case MessageType.audio.rawValue:
        messageCounter += 1
        let messageData = MessageData(apiToken: "", senderName: user, actorType: "1", seenByDoctor: "0", createdAt: Date().toString(), messageType: type, message: nil, fileName: nil, imageName: nil, audioName: file.name, videoName: nil, messageNumber: "\(messageCounter)")
      sendImageWith(message: messageData, fileData: file, type: type)
      break
    default:
      break
    }
  }
}

extension DoctorChatViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return chatData.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let type = chatData[indexPath.row].messageType
    
    switch type {
    case "text":
      let cell = tableView.dequeueReusableCell(withIdentifier: "textCell", for: indexPath) as! ChatTextTableViewCell
      cell.messageTextLabel.text = chatData[indexPath.row].message
      cell.dateLabel.text = chatData[indexPath.row].createdAt
      let actorType = chatData[indexPath.row].actorType
      if actorType == "1" {
        cell.nameLabel.text = chatData[indexPath.row].senderName
        cell.seenImageView.image = chatData[indexPath.row].seenByDoctor == "1" ? UIImage(named: "Sent") : UIImage(named: "check")
        cell.containerView.backgroundColor = .white
        cell.containerViewLeading.constant = 12
        cell.containerViewTrailing.constant = 48
      } else {
        cell.nameLabel.text = chatData[indexPath.row].senderName
        cell.containerView.backgroundColor = #colorLiteral(red: 1, green: 0.9018902779, blue: 0.9081988931, alpha: 1)
        cell.containerViewLeading.constant = 48
        cell.containerViewTrailing.constant = 12
      }
      return cell
    case "image":
      let cell = tableView.dequeueReusableCell(withIdentifier: "imageCell", for: indexPath) as! ChatImageTableViewCell
      
      let reference = storageRef.child(chatData[indexPath.row].imageName!)
      cell.messageImageView.sd_imageTransition = .fade
      cell.messageImageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
      cell.messageImageView.sd_setImage(with: reference)
      
      cell.dateLabel.text = chatData[indexPath.row].createdAt
      let actorType = chatData[indexPath.row].actorType
      if actorType == "1" {
        cell.seenImageView.image = chatData[indexPath.row].seenByDoctor == "1" ? UIImage(named: "Sent") : UIImage(named: "check")
        cell.containerViewLeading.constant = 12
        cell.containerViewTrailing.constant = 48
      } else {
        cell.containerViewLeading.constant = 48
        cell.containerViewTrailing.constant = 12
      }
      return cell
    case "file":
      let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as! ChatFileTableViewCell
      cell.fileNameLabel.text = chatData[indexPath.row].fileName
      cell.dateLabel.text = chatData[indexPath.row].createdAt
      let actorType = chatData[indexPath.row].actorType
      if actorType == "1" {
        cell.seenImageView.image = chatData[indexPath.row].seenByDoctor == "1" ? UIImage(named: "Sent") : UIImage(named: "check")
        cell.containerView.backgroundColor = .white
        cell.containerViewLeading.constant = 12
        cell.containerViewTrailing.constant = 48
      } else {
        cell.containerView.backgroundColor = #colorLiteral(red: 1, green: 0.9018902779, blue: 0.9081988931, alpha: 1)
        cell.containerViewLeading.constant = 48
        cell.containerViewTrailing.constant = 12
      }
      return cell
    case "video":
      let cell = tableView.dequeueReusableCell(withIdentifier: "videoCell", for: indexPath) as! ChatVideoTableViewCell
      cell.dateLabel.text = chatData[indexPath.row].createdAt
      let actorType = chatData[indexPath.row].actorType
      
      if actorType == "1" {
        cell.seenImageView.image = chatData[indexPath.row].seenByDoctor == "1" ? UIImage(named: "Sent") : UIImage(named: "check")
        cell.containerViewLeading.constant = 12
        cell.containerViewTrailing.constant = 48
      } else {
        cell.containerViewLeading.constant = 48
        cell.containerViewTrailing.constant = 12
      }
      return cell
    case "audio":
      let cell = tableView.dequeueReusableCell(withIdentifier: "audioCell", for: indexPath) as! ChatAudioTableViewCell
      
      cell.playButtonTapped = {
        self.timer?.invalidate()
        self.timer = nil
        let audioName = self.chatData[indexPath.row].audioName ?? ""
        self.saveDataWith(imageName: audioName, completionHandler: { _ in
          guard let filePath = self.getSavedDataURL(with: audioName) else {return}
            do{
                try self.session.overrideOutputAudioPort(.speaker)
            }catch let err{
                print(err)
            }
          self.player = try! AVAudioPlayer(contentsOf: filePath)
          guard let player = self.player else { return }
          if cell.playButton.isSelected {
            player.stop()
            cell.playButton.isSelected = false
          } else {
            player.play()
            cell.slider.minimumValue = 0
            cell.slider.maximumValue = Float(player.duration)
            cell.slider.value = 0.01
            self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.updateSlider(timer:)), userInfo: cell, repeats: true)
            cell.playButton.isSelected = true
          }
        })
      }
      
      cell.dateLabel.text = chatData[indexPath.row].createdAt
      let actorType = chatData[indexPath.row].actorType
      if actorType == "1" {
        cell.seenImageView.image = chatData[indexPath.row].seenByDoctor == "1" ? UIImage(named: "Sent") : UIImage(named: "check")
        cell.containerView.backgroundColor = .white
        cell.containerViewLeading.constant = 12
        cell.containerViewTrailing.constant = 48
      } else {
        cell.containerView.backgroundColor = #colorLiteral(red: 1, green: 0.9018902779, blue: 0.9081988931, alpha: 1)
        cell.containerViewLeading.constant = 48
        cell.containerViewTrailing.constant = 12
      }
      return cell
    default:
      return UITableViewCell()
    }
  }
  
  @objc func updateSlider(timer: Timer) {
    let cell = timer.userInfo as! ChatAudioTableViewCell
    cell.slider.setValue(Float(player!.currentTime), animated: true)
    if ceil(Double(player!.currentTime)) >= Double(player!.duration) {
      cell.playButton.isSelected = false
    }
  }
}

extension DoctorChatViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let type = chatData[indexPath.row].messageType
    
    switch type {
    case MessageType.image.rawValue:
      let chatImageVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chatImageVC") as! ChatImageViewController
      chatImageVC.imageName = chatData[indexPath.row].imageName
      chatImageVC.modalPresentationStyle = .fullScreen
      present(chatImageVC, animated: true, completion: nil)
      
      break
    case MessageType.file.rawValue:
      let fileName = chatData[indexPath.row].fileName ?? ""
      let starsRef = storageRef.child(fileName)
      starsRef.downloadURL { url, error in
        if error == nil {
          UIApplication.shared.open(url!, options: [:], completionHandler: nil)
        }
      }
      
      break
    case MessageType.video.rawValue:
      let videoName = chatData[indexPath.row].videoName ?? ""
      let starsRef = storageRef.child(videoName)
      starsRef.downloadURL { url, error in
        if error == nil {
          let player = AVPlayer(url: url!)
          let playerViewController = AVPlayerViewController()
          playerViewController.player = player
          self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
          }
        }
      }
      
      break
    default:
      break
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    let type = chatData[indexPath.row].messageType
    switch type {
    case "text":
      return UITableView.automaticDimension
    case "image":
      return 180
    case "file":
      return 64
    case "audio":
      return 72
    case "video":
      return 220
    default:
      return 64
    }
  }
}

extension DoctorChatViewController {
  struct SendMessageResponse: Codable {
    let status: Bool
    let errNum: String
    let msg: String
    let message: MessageData?
  }
  
  struct MessageData: Codable {
    let apiToken: String?
    let senderName: String?
    let actorType: String?
    let seenByDoctor: String?
    let createdAt: String?
    let messageType: String?
    let message: String?
    let fileName: String?
    let imageName: String?
    let audioName: String?
    let videoName: String?
    let messageNumber:String?
  }
}

extension DoctorChatViewController {
  func startRecording() {
    let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
    let settings = [
      AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
      AVSampleRateKey: 12000,
      AVNumberOfChannelsKey: 1,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]
    
    do {
      audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
      audioRecorder.delegate = self
      audioRecorder.record()
    } catch {
      finishRecording(success: false)
    }
  }
  func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
  }
  
  func finishRecording(success: Bool) {
    audioRecorder.stop()
    audioRecorder = nil
    if success {
      guard let data = try? Data(contentsOf: getDocumentsDirectory().appendingPathComponent("recording.m4a")) else {return}
      let fileData = FileData(data: data, name: "File\(String.randomString(length: 20)).m4a")
      returnWith(file: fileData, type: "audio")
    }
  }
}

extension DoctorChatViewController: RecordViewDelegate {
  func onStart() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      self.recordView.isHidden = false
      self.startRecording()
    }
  }
  
  func onCancel() {}
  
  func onFinished(duration: CGFloat) {
    if duration >= 1 && duration <= 60 {
      finishRecording(success: true)
      recordView.isHidden = true
    }else if duration >= 1{
        finishRecording(success: false)
        recordView.isHidden = true
        let resourcePath = Bundle.main.resourcePath
                let stringURL = resourcePath! + "/sms-alert-3-daniel_simon.mp3" //change foo to your file name you have added in project
                let url = URL.init(fileURLWithPath: stringURL)
                player = try! AVAudioPlayer(contentsOf: url)
        guard let player = self.player else {
            return
        }
        do{
            try self.session.overrideOutputAudioPort(.speaker)
        }catch let err{
            print(err)
        }
        let alert = UIAlertController(title: "Alert", message: "sound is can not be more than 1 minute", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
            player.stop()
                }))
                player.play()
                self.present(alert, animated: true, completion: nil)
    }
  }
}

extension DoctorChatViewController: AVAudioRecorderDelegate {
  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    if !flag {
      finishRecording(success: false)
    }
  }
}

extension DoctorChatViewController {
  func saveDataWith(imageName: String, completionHandler: @escaping(_: Bool)->()) {
    let storageRef = Storage.storage().reference()
    let imageFilePath = getDocumentsDirectory().appendingPathComponent(imageName)
    if !FileManager.default.fileExists(atPath: imageFilePath.path) {
      storageRef.child(imageName).write(toFile: imageFilePath) { (_, error) in
        if let _ = error {
          completionHandler(false)
        } else {
          completionHandler(true)
        }
      }
    } else {
      completionHandler(true)
    }
  }
  
  func getSavedDataURL(with name: String) -> URL? {
    let imagePath = getDocumentsDirectory().appendingPathComponent(name)
    if FileManager.default.fileExists(atPath: imagePath.path) {
      return imagePath
    }
    return nil
  }
}

extension Date {
  func toString() -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "En")
    formatter.dateFormat = "dd MMM yyyy HH:mm"
    
    return formatter.string(from: self)
  }
}

extension String {
  static func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
  }
}

extension DoctorChatViewController {
  @objc func keyboardWillShow(notification:NSNotification) {
    let info = notification.userInfo!
    let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
    
    UIView.animate(withDuration: 0.1, animations: { () -> Void in
      let window = UIApplication.shared.keyWindow
      let bottomPadding = window?.safeAreaInsets.bottom
      if let bottomPadding = bottomPadding {
        self.bottomConstraint.constant = keyboardFrame.size.height - 52 - bottomPadding
      }
    })
  }
  
  @objc func keyboardWillHide(notification:NSNotification) {
    UIView.animate(withDuration: 0.1, animations: { () -> Void in
      self.bottomConstraint.constant = 0
    })
  }
}
extension DoctorChatViewController:ChatAttechedVideoBigger{
    func showVideoAlert() {
        let resourcePath = Bundle.main.resourcePath
                let stringURL = resourcePath! + "/sms-alert-3-daniel_simon.mp3" //change foo to your file name you have added in project
                let url = URL.init(fileURLWithPath: stringURL)
                player = try! AVAudioPlayer(contentsOf: url)
        guard let player = self.player else {
            return
        }
        do{
            try self.session.overrideOutputAudioPort(.speaker)
        }catch let err{
            print(err)
        }
        let alert = UIAlertController(title: "Alert", message: "video can not be more than 10 senconds", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { action in
            player.stop()
                }))
                player.play()
                self.present(alert, animated: true, completion: nil)
    }
}
