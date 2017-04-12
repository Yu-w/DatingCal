//
//  LoginViewController.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/9/17.
//
//

import Foundation
import UIKit
import AppAuth
import PromiseKit
import GoogleAPIClientForREST
import SwiftyJSON
import RealmSwift

class LoginViewController: UIViewController {
    
    private let googleSession = GoogleSession()
    private var googleCalendar : GoogleCalendar?
    
    private var pendingSignIn : Promise<Void>?
    
    @IBAction func willSignIn(_ sender: Any) {
        if pendingSignIn != nil {
            print("Please wait for current login process to finish.")
            return
        }
        pendingSignIn = self.googleSession.ensureLogin(presenter: self).then { x -> Promise<Void> in
            print("Sign in finished")
            self.googleCalendar = GoogleCalendar(self.googleSession.token!)
            return self.googleCalendar!.loadAll()
        }.then { x -> Void in
            let realm = try! Realm()
            for cal in realm.objects(CalendarModel.self) {
                print(cal)
            }
        }.catch { err -> Void in
            print("ERROR: ", err)
        }.always {
            self.pendingSignIn = nil
        }
    }
    
    // When the view loads, create necessary subviews
    // and initialize the Google Calendar API service
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
