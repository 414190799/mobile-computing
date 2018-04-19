//
//  SetUsernameViewController.swift
//  Fastalk
//
//  Created by Dan Xu on 3/4/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class SetUsernameViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    private var usersRef = Constants.refs.databaseUsers
    var alertController:UIAlertController? = nil
    var usernameTextField: UITextField?
    var actionToEnable: UIAlertAction?
    
    @IBOutlet weak var photo: UIImageView!
    @IBOutlet weak var labelUsername: UILabel!
    @IBOutlet weak var labelEmail: UILabel!
    @IBOutlet weak var buttonSet: UIButton!
    
    var username: String?
    var URL: String?
    let userId = Auth.auth().currentUser?.uid
    let email = Auth.auth().currentUser?.email
    
    override func viewDidLoad() {
        super.viewDidLoad()
        labelEmail.text = self.email
        self.title = "Complete Profile"
        //self.buttonDone.isEnabled = false
    }
    
    // TODO: - Require username

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Private Methods
    
    private func presentAlert() {
        self.alertController = UIAlertController(title: "Set Username", message: "", preferredStyle: UIAlertControllerStyle.alert)
        self.alertController!.addTextField { (textField) -> Void in
            self.usernameTextField = textField
            self.usernameTextField?.placeholder = "Enter the username"
        }
        let OKAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            self.username = self.usernameTextField!.text
            self.labelUsername.text = self.username
            //self.buttonDone.isEnabled = true
            self.buttonSet.isHidden = true
        })
        
        OKAction.isEnabled = false
        actionToEnable = OKAction
        self.alertController!.addAction(OKAction)
        self.present(self.alertController!, animated: true, completion:nil)
        
        self.usernameTextField!.addTarget(self, action: #selector(checkIfUserExists), for: .editingChanged)
    }
    
    private func updateUserInfo() {
        let userItem = [
            "username": self.username!,
            "email": self.email
        ]
        self.usersRef.child(self.userId!).setValue(userItem)
        
        //Config.setUsername(self.username!)
    }
    
    private func uploadFirebase() {
        let storage = Storage.storage()
        let storageRef = storage.reference().child("\(username!)")
        if let uploadData = UIImagePNGRepresentation(self.photo.image!) {
            storageRef.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print(error)
                    return
                }
                self.URL = metadata?.downloadURL()?.absoluteString
            })
        }
    }
    
    @objc func checkIfUserExists() {
        self.alertController?.message = "Checking..."
        let username = usernameTextField!.text
        guard !(username?.isEmpty)! else {
            return
        }
        self.usersRef.queryOrdered(byChild: "username").queryEqual(toValue: username).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.exists()) {
                self.alertController?.message = "User already exists"
                self.actionToEnable!.isEnabled = false
            } else {
                self.alertController?.message = "Nice Name"
                self.actionToEnable!.isEnabled = true
            }
        })
    }
    
    // MARK: - UI Actions
    @IBAction func setClickedAction(_ sender: Any) {
        presentAlert()
    }
    
    @IBAction func uploadPic(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = true
        self.present(image, animated: true){
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            photo.image = image
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buttonDone(_ sender: Any) {
        uploadFirebase()
        self.updateUserInfo()
    }
    /*
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
