//
//  SettingsUserCellView.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/23/17.
//
//

import Foundation
import UIKit

class SettingsUserCellView: UITableViewCell {
    
    @IBOutlet var userEmailLabel: UILabel!
    
    /// update the cell's content with a model object
    func configureData(user: UserModel) {
        userEmailLabel.text = user.email
    }
    
    @IBAction func willLogout(_ sender: Any) {
    }
}
