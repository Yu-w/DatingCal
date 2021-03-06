//
//  SettingsViewController.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/23/17.
//
//

import Foundation
import UIKit
import PromiseKit
import DateTimePicker
import TextFieldEffects

class SettingsViewController: UIViewControllerWithWaitAlerts, UITableViewDataSource, UITableViewDelegate {
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let realmProvider = BusinessRealmProvider()
    
    @IBOutlet var tableView: UITableView!
    
    @IBAction func willLoginNewAccount(_ sender: Any) {
        _ = appDelegate.googleClient.acceptNewUser(self).then { _ -> Promise<Void> in
            self.showPleaseWait()
            return self.appDelegate.googleCalendar.loadAll()
        }.then { _ -> Void in
            _ = self.hidePleaseWait().then {
                self.dismiss(animated: true, completion: nil)
            }
        }.catch { err -> Void in
            self.showAlert("Error", "Login Failed")
        }.always {
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshListOfUsers()
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
    
    private func refreshListOfUsers() {
        userModels = BusinessRealmProvider().realm().objects(UserModel.self)
        tableView.reloadData()
    }
    
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
        if indexPath.row >= userModels.count {
            cell.configureAsEmpty()
        } else {
            cell.configureData(user: userModels[indexPath.row])
        }
        return cell
    }
    
    /// A currying function that handles UIAlertAction to logout an account
    /// :param index: The index of the user to be logged out
    private func willLogout(_ index: IndexPath) -> ((UIAlertAction) -> Void) {
        return { _ in
            let user = self.userModels[index.row]
            user.remove(self.realmProvider)
            _ = self.appDelegate.googleClient.ensureLogin(presenter: self).then {
                self.showPleaseWait()
                return self.appDelegate.googleCalendar.loadAll()
            }.then {
                self.refreshListOfUsers()
            }.always {
                _ = self.hidePleaseWait()
            }
        }
    }
    
    /// A currying function that handles UIAlertAction to clear events in an account
    /// :param index: The index of the account to be cleared
    private func willClearOurEvents(_ index: IndexPath) -> ((UIAlertAction) -> Void) {
        return { _ in
            let user = self.userModels[index.row]
            
            /// We will need to change primary user before deleting events.
            self.showPleaseWait()
            _ = self.appDelegate.googleClient.temporarilyChangeUser(user, self).then {
                return self.appDelegate.googleCalendar.clearOurCalendar()
            }.then {
                self.dismiss(animated: true, completion: nil)
            }.catch { err in
                self.showAlert("Failed to clear events", err.localizedDescription)
            }.always {
                self.hidePleaseWait()
                self.appDelegate.googleClient.cancelTemporaryChangedUser()
            }
        }
    }
    
    /// A currying function that handles UIAlertAction to set primary account
    /// :param index: The index of the user to be set as primary user
    private func willSetPrimaryUser(_ index: IndexPath) -> ((UIAlertAction) -> Void) {
        return { _ in
            self.showPleaseWait()
            let user = self.userModels[index.row]
            _ = self.appDelegate.googleClient.changeUser(user, self).then {
                return self.appDelegate.googleCalendar.loadAll()
            }.then {
                self.refreshListOfUsers()
            }.always {
                _ = self.hidePleaseWait()
            }
        }
    }
    
    /// animate the deselection of the selection of rows
    /// Code created by Yu Wang
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Set it as primary account", style: .default, handler: willSetPrimaryUser(indexPath)))
        alert.addAction(UIAlertAction(title: "Sign off this account", style: .destructive, handler: willLogout(indexPath)))
        alert.addAction(UIAlertAction(title: "Delete all \"DatingCal\" events in this account", style: .destructive, handler: willClearOurEvents(indexPath)))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))
        self.present(alert, animated: true)
    }
    
}
