//
//  ViewController.swift
//  Fastalk
//
//  Created by Dan Xu on 2/25/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController,UIBarPositioningDelegate  {
    var chat: Chat?
    var userId = Auth.auth().currentUser!.uid
    let messagesRef = Constants.refs.databaseMessagesByChat
    let messagesByUserRef = Constants.refs.databaseMessagesByUser
    var userMessagesRef: DatabaseReference?
    var userChatRef: DatabaseReference?
    var friendChatRef: DatabaseReference?
    private var messagesRefHandle: DatabaseHandle?
    var messages = [JSQMessage]()
    let usersRef = Constants.refs.databaseUsers
    let groupChatsRef = Constants.refs.databaseGroups
    //var navigationBar : UINavigationBar?
    var fontSize = SettingsViewController.global.font
    
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }()

    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()
    
    // TODO: - show username if group chat
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.title = chat?.receiverName
        self.userMessagesRef = messagesRef.child(chat!.id)
        self.userChatRef = Constants.refs.databaseChats.child(userId).child(chat!.id)
        let receiverId = self.chat?.receiverId
        if (receiverId != "group") {
            self.friendChatRef = Constants.refs.databaseChats.child(chat!.receiverId).child(chat!.id)
        }
        observeMessages()
        
        edgesForExtendedLayout = []
        inputToolbar.contentView.leftBarButtonItem = nil
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(ChatViewController.tapToDismissKeyboard(_:)))
        view.addGestureRecognizer(tapRecognizer)
        addNavBar()
        topContentAdditionalInset = 60
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.userChatRef!.updateChildValues(["hasNewMessage" : false])
    }
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Overriden Methods

    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData!
    {
        return messages[indexPath.item]
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return messages.count
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource!
    {
        return messages[indexPath.item].senderId == senderId ? outgoingBubble : incomingBubble
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource!
    {
        return nil
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        if fontSize == 0{
            fontSize = 20
        }
        let font = CGFloat(fontSize)
        cell.textView?.font = UIFont.systemFont(ofSize:font)
        return cell
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString!
    {
        let receiverId = chat?.receiverId
        if (receiverId == "group") {
            return messages[indexPath.item].senderId == senderId ? nil : NSAttributedString(string: messages[indexPath.item].senderDisplayName)
        }
        return nil
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat
    {
        let receiverId = chat?.receiverId
        if (receiverId == "group") {
            return messages[indexPath.item].senderId == senderId ? 0 : 15
        }
        return 0
    }

    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!)
    {
        let itemRef = userMessagesRef!.childByAutoId()
        let date = getDate()
        let receiverName = chat?.receiverName
        let receiverId = chat?.receiverId
        let messageItem = [
            "senderId": self.senderId,
            "senderName": self.senderDisplayName,
            "receiverName": receiverName!,
            "receiverId": receiverId!,
            "text": text!,
            "timeStamp": date
        ]
        
        itemRef.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()

        messagesByUserRef.child(userId).child(itemRef.key).setValue(messageItem)
        if (receiverId != "group") {
            messagesByUserRef.child(receiverId!).child(itemRef.key).setValue(messageItem)
        }
        
        //update chat
        self.userChatRef!.updateChildValues(["timeStamp" : date])
        self.userChatRef!.updateChildValues(["lastMessage" : text])
        if (receiverId != "group") {
            let chatItem = [
                "lastMessage" : text,
                "receiverId" : self.senderId,
                "receiverName" : self.senderDisplayName,
                "timeStamp" : date,
                "hasNewMessage": true
                ] as [String : Any]
            self.friendChatRef?.setValue(chatItem)
        } else {
            self.groupChatsRef.child(self.chat!.id).updateChildValues(["timeStamp" : date])
            self.groupChatsRef.child(self.chat!.id).updateChildValues(["lastMessage" : text])
            self.groupChatsRef.child(self.chat!.id).updateChildValues(["hasNewMessage" : true])
        }
        
        finishSendingMessage()
    }
    
    // MARK: - Private Methods
    private func observeMessages() {
        let messageQuery = userMessagesRef!.queryLimited(toLast:25)
        messagesRefHandle = messageQuery.observe(.childAdded, with: { (snapshot) -> Void in
            let messageData = snapshot.value as! Dictionary<String, String>
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String!, let text = messageData["text"] as String!, text.count > 0 {
                self.addMessage(withId: id, name: name, text: text)
                self.finishReceivingMessage()
            } else {
                print("Error! Could not decode message data")
            }
        })
    }
    
    private func getDate() -> String{
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm MM/dd/yy"
        let convertedDate = dateFormatter.string(from: currentDate)
        return convertedDate
    }

    private func addMessage(withId id: String, name: String, text: String) {
        if let message = JSQMessage(senderId: id, displayName: name, text: text) {
            messages.append(message)
        }
    }
    
    @objc func tapToDismissKeyboard(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @IBAction func backToStart(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle:nil)
        let initialView = storyboard.instantiateViewController(withIdentifier: "startNavigation")
        self.present(initialView, animated: true, completion: nil)
    }
    
    @IBAction func exit(_ sender: Any) {
        self.dismiss(animated: false) {
            let storyboard = UIStoryboard(name: "Main", bundle:nil)
            let initialView = storyboard.instantiateViewController(withIdentifier: "startNavigation")
            self.present(initialView, animated: false, completion: nil)
        }
    }
    
    func addNavBar() {
        
        let navigationBar = UINavigationBar(frame: CGRect(x: 0, y: 20, width: UIScreen.main.bounds.width, height:50)) // Offset by 20 pixels vertically to take the status bar into account
        navigationBar.prefersLargeTitles = true
        navigationBar.barTintColor = UIColor(named: navColor[Config.colorScheme()])
        navigationBar.tintColor = UIColor.white
        
        navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        //navigationBar.titleTextAttributes
        
        // Create a navigation item with a title
        let navigationItem = UINavigationItem()
        navigationItem.title = chat?.receiverName
        
        // Create left and right button for navigation item
        let leftButton =  UIBarButtonItem(title: "Back", style:   .plain, target: self, action: #selector(btn_clicked(_:)))
        
        let rightButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(btn_clicked(_:)))
        
        // Create two buttons for the navigation item
        navigationItem.leftBarButtonItem = leftButton
        navigationItem.rightBarButtonItem = rightButton
        
        // Assign the navigation item to the navigation bar
        navigationBar.items = [navigationItem]
        
        // Make the navigation bar a subview of the current view controller
        self.view.addSubview(navigationBar)
    }
    
    @objc func btn_clicked(_ sender: UIBarButtonItem) {
        // Do something
        let storyboard = UIStoryboard(name: "Main", bundle:nil)
        let initialView = storyboard.instantiateViewController(withIdentifier: "startNavigation")
        self.present(initialView, animated: true, completion: nil)
    }
    
    
}

