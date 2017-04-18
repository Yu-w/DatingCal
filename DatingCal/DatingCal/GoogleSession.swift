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
class GoogleSession : AbstractSession {
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
    
    /// A helper function that returns a promise to refresh the token stored in _authState
    ///  authState: unwrapped value in self._authState
    private func refreshToken(authState: OIDAuthState) -> Promise<String> {
        return Promise { fulfill, reject in
            authState.performAction(freshTokens: { token, id, err in
                if let err = err {
                    reject(err)
                    return
                }
                fulfill(token!)
            })
        }
    }
    
    var isLoggedIn : Bool {
        get {
            return _authState != nil
        }
    }
    
    var token : Promise<String> {
        return firstly {
            guard let authState = self._authState else {
                throw GoogleError.NotLoggedIn
            }
            return refreshToken(authState: authState)
        }
    }
    
    let sequentialLogin = SequentialPromise<Void>()
    
    /// This function will ensure the user is logged in.
    /// But rest assured, it will only call login() when necessary.
    func ensureLogin(presenter: UIViewController) -> Promise<Void> {
        loadAuthState()
        return sequentialLogin.neverAppend {
            guard let authState = self._authState else {
                return self.login(presenter: presenter)
            }
            return Promise { fulfill, reject in
                authState.performAction(freshTokens: { token, id, err in
                    if let err = err {
                        reject(err)
                        return
                    }
                    fulfill()
                })
            }.recover {err -> Promise<Void> in
                debugPrint("Failed to refresh access token. Reason: ", err)
                return self.login(presenter: presenter)
            }
        }
    }
    
    func logout() {
        self._authState = nil
        try? FileManager.default.removeItem(atPath: googleAuthStateStorage)
    }
    
}
