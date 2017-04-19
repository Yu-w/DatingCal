//
//  RealHTTPClient.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/16/17.
//
//

import AppAuth
import Alamofire
import Foundation
import PromiseKit
import RealmSwift
import SwiftyJSON
import GoogleAPIClientForREST

/// An abstraction for Google HTTP client, with automatic authorizations.
/// There are two implementations:
///     GoogleHTTPClient will actually call Google.
///     FakeHTTPClient is created for test cases, and will not call Google.
protocol AbstractHTTPClient {
    
    /// Wrap any JSON-based Alamofire request in a Promise
    /// Encoding method will be set to JSONEncoding.default
    /// (PromiseKit/Alamofire- isn't working...)
    func request(_ url: URLConvertible,
                 method: HTTPMethod,
                 parameters: Parameters?) -> Promise<JSON>
}

class GoogleHTTPClient : AbstractHTTPClient {
    private let kScopes : [String]? = [
        "https://www.googleapis.com/auth/calendar",         // Manage calendars
        "https://www.googleapis.com/auth/plus.me"           // Get unique user ID
    ]
    private let kRedirectURI : URL = URL(string: "cs242.datingcal:/oauth2redirect/google")!
    private let kClientId = "674497672844-d33bqapee8lm5l90l021sml0nsbvu3qp.apps.googleusercontent.com"
    private let kIssuer = URL(string: "https://accounts.google.com")!
    
    private var googleAuthStateStorage : String {
        get {
            let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
            return library + "/google-auth-state.dat"
        }
    }
    
    /// This object stores all the tokens and login states
    private var _authState : OIDAuthState?
    
    /// Save login state to hard drive
    private func saveAuthState() {
        if let state = _authState {
            NSKeyedArchiver.archiveRootObject(state, toFile: googleAuthStateStorage)
        }
    }
    
    /// Load login state from hard drive
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
        return OIDAuthorizationService.getConfigurations(issuer: kIssuer).then { config -> Promise<OIDAuthState> in
            let request = OIDAuthorizationRequest(configuration: config
                , clientId: self.kClientId, clientSecret: nil
                , scopes: self.kScopes, redirectURL: self.kRedirectURI
                , responseType: OIDResponseTypeCode, additionalParameters: nil)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let (flow, promise) = OIDAuthState.authState(request: request, presenter: presenter)
            appDelegate.googleAuthFlow = flow
            return promise
        }.then { authState -> Void in
            self._authState = authState
            self.saveAuthState()
        }
    }
    
    var isLoggedIn : Bool {
        get {
            return _authState != nil
        }
    }
    
    var token : Promise<String> {
        return firstly { _ -> Promise<(String?, String?)> in
            guard let authState = self._authState else {
                throw GoogleError.NotLoggedIn
            }
            return authState.performAction()
        }.then { (token ,id) -> String in
            return token!
        }
    }
    
    var userId : Promise<String> {
        get {
            return self.token.then { token -> Promise<String> in
                self.request("https://www.googleapis.com/plus/v1/people/me",
                             method: .get,
                             parameters: nil).then { json -> String in
                    json["id"].string!
                }
            }
        }
    }
    
    /// This function will ensure the user is logged in.
    /// But rest assured, it will only call login() when necessary.
    func ensureLogin(presenter: UIViewController) -> Promise<Void> {
        loadAuthState()
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
    
    func logout() {
        self._authState = nil
        try? FileManager.default.removeItem(atPath: googleAuthStateStorage)
    }
    
    func request(_ url: URLConvertible,
                 method: HTTPMethod,
                 parameters: Parameters?) -> Promise<JSON> {
        return self.token.then { _token in
            let headers : HTTPHeaders = ["Authorization":"Bearer " + _token]
            let encoding : ParameterEncoding = parameters==nil ? URLEncoding.default : JSONEncoding.default
            let requested = Alamofire.request(url, method: method,
                                              parameters: parameters,
                                              encoding: encoding,
                                              headers: headers)
            return Promise {fulfill, reject in
                requested.responseJSON(completionHandler: { response in
                    if let err = response.error {
                        reject(err)
                    } else if let data = response.data {
                        let json = JSON(data: data)
                        if let error = json.dictionary?["error"] {
                            reject(GoogleError.ErrorInJson(error))
                        } else {
                            fulfill(json)
                        }
                    }
                })
            }
        }
    }
}
