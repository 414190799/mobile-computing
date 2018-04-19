//
//  ChatsListTableViewCell.swift
//  Fastalk
//
//  Created by Dan Xu on 4/15/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import UIKit

class ChatsListTableViewCell: UITableViewCell {
    @IBOutlet weak var labelReceiver: UILabel!
    @IBOutlet weak var labelLastMessage: UILabel!
    @IBOutlet weak var labelTime: UILabel!
    @IBOutlet weak var imageBell: UIImageView!
    var hasNewMessage = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
