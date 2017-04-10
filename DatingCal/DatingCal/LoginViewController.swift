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

class LoginViewController: UIViewController {
    
    private let kKeychainItemName = "Google Calendar API"
    private let kClientID = "674497672844-d33bqapee8lm5l90l021sml0nsbvu3qp.apps.googleusercontent.com"
    private let kClientSecret = "???"
    private let kRedirectURI = "???"
    private let kIssuer = "https://accounts.google.com"
    
    let signInButton = UIButton()
    
    func willSignIn() {
        firstly {
            Promise { fufill, reject in
                fufill(123)
            }
        }
        /*
        OIDAuthorizationService.discoverConfiguration(forIssuer: kIssuer, completion: <#T##OIDDiscoveryCallback##OIDDiscoveryCallback##(OIDServiceConfiguration?, Error?) -> Void#>)
        let request = OIDAuthorizationRequest(configuration: config, clientId: kClientID, clientSecret: kClientSecret, scope: kScope, redirectURL: kRedirectURI, responseType: OIDResponseTypeCode, additionalParameters: nil)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.googleAuthFlow = OIDAuthState.authState(byPresenting: request, presenting: self, callback: { (authState: OIDAuthState, err: NSError) in
            return
        })
 **/
    }
    
    // When the view loads, create necessary subviews
    // and initialize the Google Calendar API service
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.addTarget(self, action: #selector(willSignIn), for: .touchUpInside)
        view.addSubview(signInButton)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
