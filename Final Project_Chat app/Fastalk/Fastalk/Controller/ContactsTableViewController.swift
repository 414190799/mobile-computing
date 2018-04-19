//
//  ContactsTableViewController.swift
//  Fastalk
//
//  Created by Dan Xu on 3/6/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import UIKit
import Firebase

class ContactsTableViewController: UITableViewController {
    private var contacts: [Contact] = []
    private var contactsRef = Constants.refs.databaseContacts
    private var userContactsRef: DatabaseReference?
    private var userContactsRefHandle: DatabaseHandle?
    private var usersRef = Constants.refs.databaseUsers
    private var friendChatsRef: DatabaseReference?
    private var chatsRef = Constants.refs.databaseChats
    let userId = Auth.auth().currentUser!.uid
    var username: String?
    var selectedChat: Chat?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Contacts"
        getUsername()
        startObserve()
    }

    deinit {
        if let refHandle = userContactsRefHandle {
            self.userContactsRef!.removeObserver(withHandle: refHandle)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    // MARK: - Overriden Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "ExistingContacts"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.text = contacts[(indexPath as NSIndexPath).row].username
        cell.imageView?.image = UIImage(named: "AppIcon")
        let imageName = contacts[(indexPath as NSIndexPath).row].username
        let imageURL = Storage.storage().reference(forURL: "gs://fastalkapp.appspot.com").child(imageName)
        imageURL.downloadURL(completion: { (url, error) in
            if error != nil {
                print(error?.localizedDescription)
                return
            }
            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
                if error != nil {
                    print(error)
                    return
                }
                guard let imageData = UIImage(data: data!) else { return}
                DispatchQueue.main.async {
                    cell.imageView?.image = imageData
                }
            }).resume()
            
        })
        return cell
    }
    
    // if user's chat exist, not add
    // if user's chat does not exist, but friend's chat exist, get the chat Id
    // if the chat does not exist on both sides, add a new chat
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
                //self.performSegue(withIdentifier: "ContactsToChat", sender: self)
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
                    //self.performSegue(withIdentifier: "ContactsToChat", sender: self)
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
            if let contactName = contactsData["username"] as! String!, contactName.count > 0 {
                self.contacts.append(Contact(username: contactName, userId: contactId))
                self.tableView.reloadData()
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

}
