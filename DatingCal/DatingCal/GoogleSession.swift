//
//  GoogleSession.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/11/17.
//
//

import Foundation
import AppAuth
import PromiseKit
import GoogleAPIClientForREST
import SwiftyJSON
import RealmSwift

/// Manages a login session with some Google user.
/// It manages the cache of login tokens and decide whether it's needed to start login process.
class GoogleSession {
    private let kScopes : [String]? = ["https://www.googleapis.com/auth/calendar"]
    private let kRedirectURI : URL = URL(string: "cs242.datingcal:/oauth2redirect/google")!
    private let kClientId = "674497672844-d33bqapee8lm5l90l021sml0nsbvu3qp.apps.googleusercontent.com"
    
    private let googleAuth = OIDPromise(issuer: URL(string: "https://accounts.google.com")!)
    private var googleAuthStateStorage : String {
        get {
            let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
            return library + "/google-auth-state.dat"
        }
    }
    
    private var _authState : OIDAuthState?
    
    var authState : OIDAuthState? { get {return _authState} }
    var token : String? { get {return authState?.lastTokenResponse?.accessToken} }
    
    private func saveAuthState() {
        if let state = _authState {
            NSKeyedArchiver.archiveRootObject(state, toFile: googleAuthStateStorage)
        }
    }
    
    private func loadAuthState() {
        guard let data = NSData(contentsOfFile: googleAuthStateStorage) else {
            return
        }
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data as Data)
        unarchiver.requiresSecureCoding = false
        self._authState = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? OIDAuthState
    }
    
    /// A helper function that actually does the login.
    private func login(presenter: UIViewController) -> Promise<Void> {
        return googleAuth.getConfigurations().then { config -> Promise<OIDAuthState> in
            let request = OIDAuthorizationRequest(configuration: config
                , clientId: self.kClientId, clientSecret: nil
                , scopes: self.kScopes, redirectURL: self.kRedirectURI
                , responseType: OIDResponseTypeCode, additionalParameters: nil)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let (flow, promise) = self.googleAuth.authState(request: request, presenter: presenter)
            appDelegate.googleAuthFlow = flow
            return promise
        }.then { authState -> Void in
            self._authState = authState
            self.saveAuthState()
        }
    }
    
    /// This function will ensure the user is logged in.
    /// But rest assured, it will only call login() when necessary.
    func ensureLogin(presenter: UIViewController) -> Promise<Void> {
        loadAuthState()
        if let authState = self.authState {
            return Promise { fulfill, reject in
                authState.performAction(freshTokens: { token, id, err in
                    if let err = err {
                        reject(err)
                        return
                    }
                    fulfill()
                })
            }.recover {err -> Promise<Void> in
                print("Failed to refresh access token. Reason: ", err)
                return self.login(presenter: presenter)
            }
        } else {
            return login(presenter: presenter)
        }
    }
    
    var isLoggedIn : Bool {
        get {
            return authState != nil
        }
    }
    
    func logout() {
        self._authState = nil
        try? FileManager.default.removeItem(atPath: googleAuthStateStorage)
    }
    
}
