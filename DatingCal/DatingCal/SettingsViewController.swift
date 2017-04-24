//
//  SettingsViewController.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/23/17.
//
//

import Foundation
import UIKit
import DateTimePicker
import TextFieldEffects

class SettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userModels = BusinessRealmProvider().realm().objects(UserModel.self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func didClickDone(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // -------------------- Functions below are related to TABLE VIEW
    
    var userModels = BusinessRealmProvider().realm().objects(UserModel.self)
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "SettingsUserCellView", for: indexPath
            ) as! SettingsUserCellView
        cell.configureData(user: userModels[indexPath.row])
        return cell
    }
    
}
