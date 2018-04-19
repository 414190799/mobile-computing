//
//  Message.swift
//  Fastalk
//
//  Created by Dan Xu on 3/31/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import Foundation

internal class Message {
    internal let id: String
    internal let text: String
    internal let senderId: String
    internal let senderName: String
    internal let receiverId: String
    internal let receiverName: String
    internal let timeStamp: String
    
    init(id: String, text: String, senderId: String, senderName: String, receiverId: String, receiverName: String, timeStamp: String) {
        self.id = id
        self.text = text
        self.senderId = senderId
        self.senderName = senderName
        self.receiverId = receiverId
        self.receiverName = receiverName
        self.timeStamp = timeStamp
    }
}
