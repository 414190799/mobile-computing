//
//  Config.swift
//  Fastalk
//
//  Created by Dan Xu on 3/4/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import Foundation

class Config: NSObject {
    fileprivate static let kUserIdKey = "userId"
    fileprivate static let kUsernameKey = "username"
    fileprivate static let kEmailKey = "email"
    
    class func setUserId(_ userId:String) {
        UserDefaults.standard.set(userId, forKey: kUserIdKey)
        UserDefaults.standard.synchronize()
    }
    class func setUsername(_ username:String) {
        UserDefaults.standard.set(username, forKey: kUsernameKey)
        UserDefaults.standard.synchronize()
    }
    class func setEmail(_ email:String) {
        UserDefaults.standard.set(email, forKey: kEmailKey)
        UserDefaults.standard.synchronize()
    }
    
    class func userId() -> String {
        return UserDefaults.standard.object(forKey: kUserIdKey) as! String
    }
    class func username() -> String {
        let username = UserDefaults.standard.object(forKey: kUsernameKey)
        if username == nil {
            return "New User"
        } else {
            return username as! String
        }
    }
    class func email() -> String {
        return UserDefaults.standard.object(forKey: kEmailKey) as! String
    }
}
