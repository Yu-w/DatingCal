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
    private lazy var googleClient : GoogleHTTPClient = { [unowned self] in
        return GoogleHTTPClient(self.googleSession)
    }()
    private lazy var googleCalendar : GoogleCalendar = { [unowned self] in
        return GoogleCalendar(self.googleClient)
    }()
    
    private var pendingSignIn : Promise<Void>?
    
    @IBAction func willSignIn(_ sender: Any) {
        if pendingSignIn != nil {
            debugPrint("Please wait for current login process to finish.")
            return
        }
        pendingSignIn = self.googleSession.ensureLogin(presenter: self).then { x -> Promise<Void> in
            debugPrint("Sign in finished")
            return self.googleCalendar.loadAll()
        }.then { x -> Void in
            let realm = try! Realm()
            for cal in realm.objects(CalendarModel.self) {
                debugPrint(cal)
            }
            self.performSegue(withIdentifier: "afterLogin", sender: self)
        }.catch { err -> Void in
            debugPrint("ERROR: ", err)
        }.always {
            self.pendingSignIn = nil
        }
    }
    
    // When the view loads, create necessary subviews
    // and initialize the Google Calendar API service
    override func viewDidLoad() {
        super.viewDidLoad()
        debugPrint(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
