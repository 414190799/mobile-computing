//
//  ChatsListTableViewController.swift
//  Fastalk
//
//  Created by Dan Xu on 3/3/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import UIKit
import Firebase

class ChatsListTableViewController: UITableViewController {
    private var chats: [Chat] = []
    private var chatsRef = Constants.refs.databaseChats
    private var usersRef = Constants.refs.databaseUsers
    private var chatsRefHandle: DatabaseHandle?
    private var currentUserChatsRef: DatabaseReference?
    var username: String?
    let userId = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Chats"
        self.currentUserChatsRef = self.chatsRef.child(self.userId!)
        observeChats()
        getUsername()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }
    
    deinit {
        if let refHandle = chatsRefHandle {
            chatsRef.removeObserver(withHandle: refHandle)
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
        return chats.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "ExistingChats"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        cell.textLabel?.text = chats[(indexPath as NSIndexPath).row].receiverName
        cell.detailTextLabel?.text = chats[(indexPath as NSIndexPath).row].timeStamp
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title:"Delete"){
            (action,view, completion) in
            self.deleteChat(indexPath)
            completion(true)
        }
        //delete.backgroundColor = color.red
        
        let config = UISwipeActionsConfiguration(actions:[delete])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    // MARK: - Privage Methods
    /* show full date if time difference larger than 24 hours
    private func showDate(_ thenDateString:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm MM/dd/yy"
        let thenDate = dateFormatter.date(from: thenDateString)
        let nowDate = Date()
        let calendar = Calendar.current
        let diffHours = calendar.dateComponents([.hour], from: thenDate!, to: nowDate).hour ?? 0
        if (diffHours >= 24) {
            return thenDateString
        } else {
            dateFormatter.dateFormat = "hh:mm"
            let convertedDate = dateFormatter.string(from: thenDate!)
            return convertedDate
        }
    }
    */
    private func observeChats() {
        chatsRefHandle = self.currentUserChatsRef?.observe(.childAdded, with: { (snapshot) -> Void in
            let chatsData = snapshot.value as! Dictionary<String, AnyObject>
            let chatId = snapshot.key
            if let receiverId = chatsData["receiverId"] as! String!, let receiverName = chatsData["receiverName"] as! String!, let timeStamp = chatsData["timeStamp"] as! String!, receiverId.count > 0 {
                self.chats.insert(Chat(id: chatId, receiverId: receiverId, receiverName: receiverName, timeStamp: timeStamp), at: 0)
                self.tableView.reloadData()
            } else {
                print("Error! Could not decode chat data")
            }
        })
    }
    
    private func getUsername() {
        self.usersRef.queryOrderedByKey().queryEqual(toValue: userId).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.exists()) {
                let user = snapshot.value as! NSDictionary
                let value = user[self.userId!] as! NSDictionary
                let username = value["username"] as! String
                self.username = username
            }
        })
    }
    
    private func deleteChat(_ indexPath: IndexPath) {
        let row = indexPath.row
        let chatId = self.chats[row].id
        self.currentUserChatsRef!.child(chatId).removeValue() { error, _ in
            print("error", error.debugDescription)
        }
        self.chats.remove(at: row)
        self.tableView.deleteRows(at: [indexPath], with: .automatic)
    }

    // MARK: - UI Actions
    @IBAction func AddClickedAction(_ sender: UIBarButtonItem) {
        let storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "popoverViewController")
        vc.modalPresentationStyle = UIModalPresentationStyle.popover
        vc.preferredContentSize = CGSize(width: 150, height: 100)
        let popover = vc.popoverPresentationController!
        popover.barButtonItem = sender
        popover.delegate = self
        present(vc, animated: true, completion:nil)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let indexPath = tableView.indexPathForSelectedRow{
            let selectedRow = indexPath.row
            let chatVc = segue.destination as! ChatViewController
            let selectedChat = chats[selectedRow]
            chatVc.chat = selectedChat
            chatVc.senderId = self.userId
            chatVc.senderDisplayName = self.username
        }
    }
    //set height
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }

}

extension ChatsListTableViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
}

