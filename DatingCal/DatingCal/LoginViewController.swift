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
    
    private let kScopes : [String]? = ["https://www.googleapis.com/auth/calendar"]
    private let kRedirectURI : URL = URL(string: "cs242.datingcal:/oauth2redirect/google")!
    private let kClientId = "674497672844-d33bqapee8lm5l90l021sml0nsbvu3qp.apps.googleusercontent.com"
    
    let googleAuth = OIDPromise(issuer: URL(string: "https://accounts.google.com")!)
    var googleAuthStateStorage : String {
        get {
            let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
            return library + "/google-auth-state.dat"
        }
    }
    
    var authState : OIDAuthState?
    var token : String?
    var googleCalendar : GoogleCalendar?
    
    func saveAuthState() {
        if let state = authState {
            NSKeyedArchiver.archiveRootObject(state, toFile: googleAuthStateStorage)
        }
    }
    
    func loadAuthState() {
        guard let data = NSData(contentsOfFile: googleAuthStateStorage) else {
            return
        }
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data as Data)
        unarchiver.requiresSecureCoding = false
        self.authState = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? OIDAuthState
    }
    
    func afterLogin() -> Promise<Void> {
        self.token = self.authState?.lastTokenResponse?.accessToken
        self.googleCalendar = GoogleCalendar(self.token!)
        return self.googleCalendar!.loadAll().then { x -> Void in
            var realm = try! Realm()
            for cal in realm.objects(CalendarModel.self) {
                print(cal)
            }
        }.catch { err -> Void in
            print("ERROR: ", err)
        }
    }
    
    @IBAction func willSignIn(_ sender: Any) {
        loadAuthState()
        if let authState = self.authState {
            afterLogin()
        } else {
            googleAuth.getConfigurations().then { config -> Promise<OIDAuthState> in
                let request = OIDAuthorizationRequest(configuration: config
                    , clientId: self.kClientId, clientSecret: nil
                    , scopes: self.kScopes, redirectURL: self.kRedirectURI
                    , responseType: OIDResponseTypeCode, additionalParameters: nil)
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let (flow, promise) = self.googleAuth.authState(request: request, presenter: self)
                appDelegate.googleAuthFlow = flow
                return promise
            }.then { authState -> Promise<Void> in
                self.authState = authState
                self.saveAuthState()
                return self.afterLogin()
            }
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
