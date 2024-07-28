//
//  CustomCellB.swift
//  Rainy Day APP
//
//  Created by 松原涼一 on 2023/09/01.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseMessaging



protocol CustomCellBDelegate {
    func addTapAction()
}


class CustomCellB: UITableViewCell {
    
    var delegate: CustomCellBDelegate?
    @IBOutlet weak var timeLabel: UILabel! 
    @IBAction func addTimeButton(_ sender: Any) {
        delegate?.addTapAction()
    }
   
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
