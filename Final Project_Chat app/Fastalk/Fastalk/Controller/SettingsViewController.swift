//
//  SettingsViewController.swift
//  Fastalk
//
//  Created by Dan Xu on 3/8/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import UIKit
import Firebase

class SettingsViewController: UIViewController {
    private var usersRef = Constants.refs.databaseUsers
    var username: String?
    var URL: String?
    let userId = Auth.auth().currentUser?.uid
    //var colorId: Int?
    var alertController:UIAlertController? = nil
    var passwordTextField: UITextField?
    var actionToEnable: UIAlertAction?
    var password = ""
    
    @IBOutlet weak var labelSignOutError: UILabel!
    @IBOutlet weak var labelUsername: UILabel!
    @IBOutlet weak var labelEmail: UILabel!
    
    @IBOutlet weak var defaultBtn: UIButton!
    @IBOutlet weak var lvBtn: UIButton!
    @IBOutlet weak var pBtn: UIButton!
    @IBOutlet weak var tBtn: UIButton!
    @IBOutlet weak var colorLb: UILabel!

    @IBOutlet weak var fontSize: UILabel!
    @IBOutlet weak var profilePic: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        getAndSetUsername()
        self.labelEmail.text = Auth.auth().currentUser?.email
        
        defaultBtn.layer.cornerRadius = 16;
        lvBtn.layer.cornerRadius = 16;
        pBtn.layer.cornerRadius = 16;
        tBtn.layer.cornerRadius = 16;
        
        colorChange(Config.colorScheme())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func getAndSetUsername() {
        self.usersRef.queryOrderedByKey().queryEqual(toValue: userId).observeSingleEvent(of: .value, with: { (snapshot) in
            if (snapshot.exists()) {
                let user = snapshot.value as! NSDictionary
                let value = user[self.userId!] as! NSDictionary
                let username = value["username"] as! String
                self.username = username
                self.labelUsername.text = username
                self.loadPic()
            }
        })
    }
    
    func loadPic() {
        let imageName = "\(self.labelUsername.text!)"
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
                    self.profilePic.image = imageData
                }
            }).resume()
            
        })
    }

    
    @IBAction func buttonLogOutClickedAction(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            labelSignOutError.text = signOutError.localizedDescription
        }
        self.performSegue(withIdentifier: "LogOutToLogIn", sender: self)
    }

    @IBAction func actionDefault(_ sender: Any) {
        colorChange(0)
    }
    @IBAction func actionLove(_ sender: Any) {
        colorChange(1)
        
    }
    @IBAction func actionPeace(_ sender: Any) {
        colorChange(2)
    }
    @IBAction func actionTradition(_ sender: Any) {
        colorChange(3)
    }
    
    func colorChange( _ colorIdx:Int){
        var schemeName:String
        switch colorIdx {
        case 0:
            schemeName = "Default"
        case 1:
            schemeName = "Love"
        case 2:
            schemeName = "Peace"
        case 3:
            schemeName = "Tradition"
        default:
            schemeName = "Default"
        }
        colorLb.text = schemeName
        Config.setColor(colorIdx)
        self.navigationController?.navigationBar.barTintColor = UIColor(named: navColor[colorIdx])
        self.tabBarController?.tabBar.tintColor = UIColor(named: tabTintColor[colorIdx])
    }
    

    @IBAction func fontAdd(_ sender: Any) {
        if let k = self.fontSize?.text{
            self.fontSize.text = String(Int(k)!+1)
            global.font = Int(k)!
        }
    }
    @IBAction func fontMinus(_ sender: Any) {
        if let k = self.fontSize?.text{
            self.fontSize.text = String(Int(k)!-1)
            global.font = Int(k)!
        }
    }
    struct global{
        static var font = Int()
    }
    
    //change password
    private func presentAlert() {
        self.alertController = UIAlertController(title: "Change Password", message: "", preferredStyle: UIAlertControllerStyle.alert)
        self.alertController!.addTextField { (textField) -> Void in
            self.passwordTextField = textField
            self.passwordTextField?.isSecureTextEntry = true
            self.passwordTextField?.placeholder = "Enter new password"
        }
        let OKAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action) -> Void in
            Auth.auth().currentUser?.updatePassword(to: self.password) { (error) in
                if let err = error {
                    self.presentError(err: err)
                }
                self.presentSuccess()
            }
        })
        
        OKAction.isEnabled = false
        actionToEnable = OKAction
        self.alertController!.addAction(OKAction)
        self.present(self.alertController!, animated: true, completion:nil)
        
        self.passwordTextField!.addTarget(self, action: #selector(checkPassword), for: .editingChanged)
    }
    
    private func presentError(err: Error) {
        self.alertController = UIAlertController(title: "Error", message: "\(err.localizedDescription)", preferredStyle: UIAlertControllerStyle.alert)
        
        let OKAction = UIAlertAction(title: "Try Again", style: UIAlertActionStyle.default)
        self.alertController!.addAction(OKAction)
        
        self.present(self.alertController!, animated: true, completion:nil)
    }
    
    private func presentSuccess() {
        self.alertController = UIAlertController(title: "Success", message: "Successfully changed password", preferredStyle: UIAlertControllerStyle.alert)
        
        let OKAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        self.alertController!.addAction(OKAction)
        
        self.present(self.alertController!, animated: true, completion:nil)
    }
    
    @objc func checkPassword() {
        self.alertController?.message = ""
        let tempPassword = self.passwordTextField!.text!
        if (tempPassword.isEmpty) {
            self.alertController?.message = "Password cannot be empty"
            return
        } else if (tempPassword.count < 6) {
            self.alertController?.message = "Password too short"
            return
        } else {
            self.alertController?.message = "Nice password"
            self.password = tempPassword
            self.actionToEnable!.isEnabled = true
        }
    }
    
    @IBAction func buttonChangePasswordClicked(_ sender: Any) {
        self.presentAlert();
    }
    
}
