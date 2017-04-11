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

class LoginViewController: UIViewController {
    
    private let kScopes : [String]? = ["https://www.googleapis.com/auth/calendar"]
    private let kRedirectURI : URL = URL(string: "cs242.datingcal:/oauth2redirect/google")!
    private let kClientId = "674497672844-d33bqapee8lm5l90l021sml0nsbvu3qp.apps.googleusercontent.com"
    
    let googleAuth = OIDPromise(issuer: URL(string: "https://accounts.google.com")!)
    
    var authState : OIDAuthState?
    var token : String?
    
    @IBAction func willSignIn(_ sender: Any) {
        googleAuth.getConfigurations().then { config -> Promise<OIDAuthState> in
            let request = OIDAuthorizationRequest(configuration: config
                , clientId: self.kClientId, clientSecret: nil
                , scopes: self.kScopes, redirectURL: self.kRedirectURI
                , responseType: OIDResponseTypeCode, additionalParameters: nil)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let (flow, promise) = self.googleAuth.authState(request: request, presenter: self)
            appDelegate.googleAuthFlow = flow
            return promise
        }.then { authState -> Promise<AnyObject> in
            self.authState = authState
            self.token = authState.lastTokenResponse?.accessToken
            return GoogleCalendar(self.token!).listCalendarLists()
        }.then { list -> Promise<AnyObject> in
            var lastCalendar : CalendarModel?
            for cal in (list as! [AnyObject]) {
                lastCalendar = CalendarModel.parse(cal)
                print(lastCalendar)
            }
            return GoogleCalendar(self.token!).listEventLists(lastCalendar!.id)
        }.then { list -> Void in
            var lastEvent : EventModel?
            for event in (list as! [AnyObject]) {
                lastEvent = EventModel.parse(event)
                print(lastEvent)
            }
        }.catch { err -> Void in
            print("ERROR: ", err)
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
