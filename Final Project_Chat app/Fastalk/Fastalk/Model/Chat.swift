//
//  Chat.swift
//  Fastalk
//
//  Created by Dan Xu on 3/3/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import Foundation

internal class Chat {
    internal let id: String
    internal let receiverId: String
    internal let receiverName: String
    internal let timeStamp: String
    
    init(id: String, receiverId: String, receiverName: String, timeStamp: String) {
        self.id = id
        self.receiverId = receiverId
        self.receiverName = receiverName
        self.timeStamp = timeStamp
    }
}
