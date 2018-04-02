//
//  SearchTableViewController.swift
//  Fastalk
//
//  Created by Dan Xu on 3/30/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import UIKit
import Firebase
enum Section: Int {
    case searchSection = 0
    case resultsSection
}

class SearchTableViewController: UITableViewController {
    var senderDisplayName: String?
    let messagesByUserRef = Constants.refs.databaseMessagesByUser
    var textFieldSearch: UITextField?
    private var messages: [Message] = []

    var userId = Auth.auth().currentUser!.uid
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Search"

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currentSection: Section = Section(rawValue: section) {
            switch currentSection {
            case .searchSection:
                return 1
            case .resultsSection:
                return messages.count
            }
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = (indexPath as NSIndexPath).section == Section.searchSection.rawValue ? "Search" : "Results"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        
        if (indexPath as NSIndexPath).section == Section.searchSection.rawValue {
            if let searchMessageCell = cell as? SearchMessageCell {
                textFieldSearch = searchMessageCell.textFieldSearchKeyword
                searchMessageCell.delegate = self;
            }
        } else if (indexPath as NSIndexPath).section == Section.resultsSection.rawValue {
            if let searchResultsCell = cell as? SearchResultsTableViewCell {
                searchResultsCell.labelMessage.text = messages[(indexPath as NSIndexPath).row].text
                searchResultsCell.labelReceiver.text = "Receiver: " + messages[(indexPath as NSIndexPath).row].receiverName
                searchResultsCell.labelSender.text = "Sender: " + messages[(indexPath as NSIndexPath).row].senderName
                // TODO: - add time here
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath as NSIndexPath).section == Section.resultsSection.rawValue {
            return 110
        } else {
            return 50
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension SearchTableViewController: SearchMessageCellProtocol {
    func searchClicked(_ sender: SearchMessageCell) {
        //let keyword = self.textFieldSearch?.text
        self.messagesByUserRef.child(userId).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.exists()) {
                let retrievedMessages = snapshot.value as! NSDictionary
                let ids = retrievedMessages.allKeys as! [String]
                for id in ids {
                    let messageContent = retrievedMessages[id] as! NSDictionary
                    let text = messageContent["text"] as! String
                    let senderId = messageContent["senderId"] as! String
                    let senderName = messageContent["senderName"] as! String
                    let receiverId = messageContent["receiverId"] as! String
                    let receiverName = messageContent["receiverName"] as! String
                    let message = Message(id: id, text: text, senderId: senderId, senderName: senderName, receiverId: receiverId, receiverName: receiverName)
                    // TODO: - filter message locally
                    self.messages.append(message)
                    self.tableView.reloadData()
                }
            }
        })
    }
}
