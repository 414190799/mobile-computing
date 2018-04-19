//
//  Constants.swift
//  Fastalk
//
//  Created by Dan Xu on 2/25/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import Foundation
import Firebase

struct Constants
{
    struct refs
    {
        static let databaseRoot = Database.database().reference()
        static let databaseMessagesByChat = databaseRoot.child("messagesByChat")
        static let databaseMessagesByUser = databaseRoot.child("messagesByUser")
        static let databaseUsers = databaseRoot.child("users")
        static let databaseChats = databaseRoot.child("chatsByUser")
        static let databaseContacts = databaseRoot.child("contactsByUser")
        static let databaseGroups = databaseRoot.child("groups")
        static let databaseMessagesByGroup = databaseRoot.child("messagesByGroup")
    }
}
