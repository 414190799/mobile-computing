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
    var alertController: UIAlertController?
    var usernameTextField: UITextField?
    var actionToEnable: UIAlertAction?
    var contactUsername: String?
    var contactUserId: String?
    var username: String?
    var selectedChat: Chat?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Contacts"
        getUsername()
        startObserve()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
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

    // MARK: - Table view data source
    // MARK: - Overriden Methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "ExistingContacts"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.text = contacts[(indexPath as NSIndexPath).row].username
        return cell
    }
    
    // TODO: - check if chat already exist
    // if chat exist, not add
    // if chat does not exist, but friend chat exist, get the chat Id
    // if chat does not exist on both sides, add a new chat
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
                let timeStamp = chatContent["timeStamp"] as! String
                let chatItem = Chat(id: id, receiverId: receiverId, receiverName: receiverName, timeStamp: timeStamp)
                self.selectedChat = chatItem
                self.performSegue(withIdentifier: "ContactsToChat", sender: self)
//                print("id", id)
//                print("receiverId", receiverId)
//                print("receiverName", receiverName)
//                print("timestamp", timeStamp)
            } else {
                self.chatsRef.child(friendId).queryOrdered(byChild: "receiverId").queryEqual(toValue: self.userId).observeSingleEvent(of: .value, with: { (snapshot) in
                    let date = self.getDate()
                    var chatId = "0"
                    if (snapshot.exists()) {
                        let chat = snapshot.value as! NSDictionary
                        chatId = chat.allKeys[0] as! String
                    } else {
                        let friendChatItem = [
                            "receiverName": self.username,
                            "receiverId": self.userId,
                            "timeStamp": date
                        ]
                        self.friendChatsRef = self.chatsRef.child(friendId)
                        let friendNewChatRef = self.friendChatsRef!.childByAutoId()
                        friendNewChatRef.setValue(friendChatItem)
                        chatId = friendNewChatRef.key
                    }
                    let userNewChatRef = self.chatsRef.child(self.userId).child(chatId)
                    let userChatItem = [
                        "receiverName": friendname,
                        "receiverId": friendId,
                        "timeStamp": date
                    ]
                    userNewChatRef.setValue(userChatItem)
                    let chatItem = Chat(id: chatId, receiverId: friendId, receiverName: friendname, timeStamp: date)
                    self.selectedChat = chatItem
                    self.performSegue(withIdentifier: "ContactsToChat", sender: self)
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
    }
    
    private func getDate() -> String{
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm MM/dd/yy"
        let convertedDate = dateFormatter.string(from: currentDate)
        return convertedDate
    }
    
    private func addNewContact() {
        let contactItem = [
            "username": self.contactUsername!
        ]
        self.userContactsRef!.child(self.contactUserId!).setValue(contactItem)
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
    
    @objc private func checkIfContactUsernameExists() {
        let contactUsername = usernameTextField!.text
        self.usersRef.queryOrdered(byChild: "username").queryEqual(toValue: contactUsername).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                self.actionToEnable!.isEnabled = true
                self.alertController?.message = "User Found"
                let contact = snapshot.value as! NSDictionary
                let keys = contact.allKeys as! [String]
                let contactUserId = keys[0]
                self.contactUserId = contactUserId
                self.contactUsername = contactUsername
            } else {
                self.alertController?.message = "User does not exist"
            }
        })
    }
    
    @IBAction func buttonAddClickedAction(_ sender: Any) {
        self.alertController = UIAlertController(title: "Add Contact", message: "Please provide the username", preferredStyle: UIAlertControllerStyle.alert)
        
        let OKAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            //add user to contacts
            self.addNewContact()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel)
        
        alertController!.addAction(OKAction)
        alertController!.addAction(cancelAction)
        
        self.alertController!.addTextField { (textField) -> Void in
            self.usernameTextField = textField
            self.usernameTextField?.placeholder = "Enter the username"
        }
        OKAction.isEnabled = false
        actionToEnable = OKAction
        present(self.alertController!, animated: true, completion:nil)
        
        self.usernameTextField!.addTarget(self, action: #selector(checkIfContactUsernameExists), for: .editingChanged)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let chatVc = segue.destination as! ChatViewController
        chatVc.chat = self.selectedChat
        chatVc.senderId = self.userId
        chatVc.senderDisplayName = self.username
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

}
