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
    
    @IBOutlet var userNameLabel: UILabel!
    
    /// update the cell's content with a model object
    func configureData(user: UserModel) {
        userNameLabel.text = user.name
    }
    
    @IBAction func willLogout(_ sender: Any) {
    }
}
