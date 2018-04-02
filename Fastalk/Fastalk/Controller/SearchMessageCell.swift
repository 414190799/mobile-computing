//
//  SearchMessageCell.swift
//  Fastalk
//
//  Created by Dan Xu on 3/30/18.
//  Copyright © 2018 IOSGroup7. All rights reserved.
//

import UIKit

protocol SearchMessageCellProtocol {
    func searchClicked(_ sender: SearchMessageCell)
}

class SearchMessageCell: UITableViewCell {
    @IBOutlet weak var textFieldSearchKeyword: UITextField!
    
    var delegate: SearchMessageCellProtocol?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    @IBAction func buttonSearchClicked(_ sender: Any) {
        delegate?.searchClicked(self)
    }
}
