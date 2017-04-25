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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBOutlet var tableView: UITableView!
    
    @IBAction func willLoginNewAccount(_ sender: Any) {
        _ = appDelegate.googleClient.acceptNewUser(self).then { _ -> Void in
            self.dismiss(animated: true, completion: nil)
        }.catch { err -> Void in
            self.showAlert("Error", "Login Failed")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        userModels = BusinessRealmProvider().realm().objects(UserModel.self)
        tableView.dataSource = self
        tableView.delegate = self
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
    
    /// animate the deselection of the selection of rows
    /// Code created by Yu Wang
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Sign off this account", style: .default))
        alert.addAction(UIAlertAction(title: "Enable/Disable synchronization", style: .default))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        self.present(alert, animated: true)
    }
    
}
