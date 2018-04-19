//
//  NewChatContactsViewController.swift
//  Fastalk
//
//  Created by Xin Su on 4/11/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import UIKit
import Firebase

class NewChatContactsViewController: UIViewController, UIBarPositioningDelegate,UITableViewDelegate, UITableViewDataSource  {
    private var contacts: [Contact] = []
    private var contactsRef = Constants.refs.databaseContacts
    private var userContactsRef: DatabaseReference?
    private var userContactsRefHandle: DatabaseHandle?
    private var usersRef = Constants.refs.databaseUsers
    private var friendChatsRef: DatabaseReference?
    private var chatsRef = Constants.refs.databaseChats
    let userId = Auth.auth().currentUser!.uid
    var alertController: UIAlertController?
    var username: String?
    var selectedChat: Chat?
    
    @IBOutlet weak var addChatContactList: UITableView!
    @IBOutlet weak var navBar: UINavigationBar!
    


    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "New Chats"
        addChatContactList.delegate = self
        addChatContactList.dataSource = self
        getUsername()
        startObserve()
        // Do any additional setup after loading the view.
        //print(contacts.count)
        self.navBar.barTintColor = UIColor(named: navColor[Config.colorScheme()])

    }
    deinit {
        if let refHandle = userContactsRefHandle {
            self.userContactsRef!.removeObserver(withHandle: refHandle)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print(contacts.count)
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "newExistingContacts"
        let cell = self.addChatContactList.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.text = contacts[(indexPath as NSIndexPath).row].username
        return cell
    }
    
    @IBAction func actionBack(_ sender: Any) {
        var parentVC = self.presentingViewController
//        parentVC?.dismiss(animated: true, completion: nil)
        parentVC = parentVC?.presentingViewController
        parentVC?.dismiss(animated: true, completion: nil)
        //self.dismiss(animated: true, completion: nil)
    }
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let friendname = contacts[indexPath.row].username
        let friendId = contacts[indexPath.row].userId
        //TODO: - change date to last message
        
        self.chatsRef.child(userId).queryOrdered(byChild: "receiverId").queryEqual(toValue: friendId).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.exists()) {
                let chat = snapshot.value as! NSDictionary
                let id = chat.allKeys[0] as! String
                let chatContent = chat[id] as! NSDictionary
                let receiverId = chatContent["receiverId"] as! String
                let receiverName = chatContent["receiverName"] as! String
                let lastMessage = chatContent["lastMessage"] as! String
                let timeStamp = chatContent["timeStamp"] as! String
                let hasNewMessage = chatContent["hasNewMessage"] as! Bool
                let chatItem = Chat(id: id, receiverId: receiverId, receiverName: receiverName, lastMessage: lastMessage, timeStamp: timeStamp, hasNewMessage: hasNewMessage)
                self.selectedChat = chatItem
//                self.performSegue(withIdentifier: "toChat", sender: self.addChatContactList)
                self.getChat()
            } else {
                self.chatsRef.child(friendId).queryOrdered(byChild: "receiverId").queryEqual(toValue: self.userId).observeSingleEvent(of: .value, with: { (snapshot) in
                    var chatId = "0"
                    if (snapshot.exists()) {
                        let chat = snapshot.value as! NSDictionary
                        chatId = chat.allKeys[0] as! String
                    } else {
                        let friendChatItem = [
                            "receiverName": self.username,
                            "receiverId": self.userId,
                            "lastMessage": "",
                            "timeStamp": "",
                            "hasNewMessage": false
                            ] as [String : Any]
                        self.friendChatsRef = self.chatsRef.child(friendId)
                        let friendNewChatRef = self.friendChatsRef!.childByAutoId()
                        friendNewChatRef.setValue(friendChatItem)
                        chatId = friendNewChatRef.key
                    }
                    let userNewChatRef = self.chatsRef.child(self.userId).child(chatId)
                    let userChatItem = [
                        "receiverName": friendname,
                        "receiverId": friendId,
                        "lastMessage": "",
                        "timeStamp": "",
                        "hasNewMessage": false
                        ] as [String : Any]
                    userNewChatRef.setValue(userChatItem)
                    let chatItem = Chat(id: chatId, receiverId: friendId, receiverName: friendname, lastMessage: "", timeStamp: "", hasNewMessage: false)
                    self.selectedChat = chatItem
                    //print("START SEGUE")
//                    self.performSegue(withIdentifier: "toChat", sender: self.addChatContactList)
                    self.getChat()
                })
            }
        })
    }
    
    // MARK: - Privage Methods
    private func startObserve() {
        let userId = Auth.auth().currentUser?.uid
        self.userContactsRef = self.contactsRef.child(userId!)
        self.userContactsRefHandle = self.userContactsRef!.observe(.childAdded, with: { (snapshot) -> Void in
            let contactId = snapshot.key
            let contactsData = snapshot.value as! Dictionary<String, AnyObject>
            if let contactName = contactsData["username"] as! String?, contactName.count > 0 {
                self.contacts.append(Contact(username: contactName, userId: contactId))
                //print(self.contacts.count)
                self.addChatContactList.reloadData()
            } else {
                print("Error! Could not decode contact data")
            }
        })
        //TODO: reorder the tabel cells according to time
    }

    private func getUsername() {
        
        self.usersRef.queryOrderedByKey().queryEqual(toValue: self.userId).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.exists()) {
                let user = snapshot.value as! NSDictionary
                let value = user[self.userId] as! NSDictionary
                let username = value["username"] as! String
                self.username = username
            }
        })
    }
    
    private func getChat(){

        let storyboard = UIStoryboard(name: "Main", bundle:nil)
        let chatVC = storyboard.instantiateViewController(withIdentifier: "chatVC") as? ChatViewController
        //let nav = UINavigationController(rootViewController: chatVC!)
        chatVC?.chat = self.selectedChat
        chatVC?.senderId = self.userId
        chatVC?.senderDisplayName = self.username
        self.present(chatVC!, animated: true, completion: nil)
        //self dismissViewControllerAnimated:NO completion:nil
    }
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let chatVc = segue.destination as! ChatViewController
//        chatVc.chat = self.selectedChat
//        chatVc.senderId = self.userId
//        chatVc.senderDisplayName = self.username
//    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

}
