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
    
    private var _userId : String?
    private let realmProvider = BusinessRealmProvider()
    
    /// This object stores all the tokens and login states
    private var _authState : OIDAuthState?
    
    /// We have to fetch a new UserModel every time
    ///    because otherwise, realm will require threadsafe references
    private var user : UserModel? {
        get {
            guard let id = _userId else {
                return nil
            }
            let realm = realmProvider.realm()
            return realm.objects(UserModel.self).filter({u in u.id == id}).first
        }
        
        set {
            guard let user = newValue else {
                _userId = nil
                return
            }
            _userId = user.id
        }
    }
    
    /// Getter for path to tokens stored in iPhone hard drive
    private var googleAuthStateStorage : String? {
        get {
            guard let user = self.user else {
                return nil
            }
            let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
            return library + user.authStorage
        }
    }
    
    init() {
        let realm = realmProvider.realm()
        let primary = realm.objects(UserModel.self).filter({u in u.isPrimary})
        guard let primaryFirst = primary.first else {
            user = nil
            return
        }
        self.user = primaryFirst
    }
    
    /// A helper function that actually does the login.
    private func login(presenter: UIViewController) -> Promise<Void> {
        return OIDAuthorizationService.getConfigurations().then { config -> Promise<OIDAuthState> in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let (flow, promise) = OIDAuthState.startLogin(config, presenter)
            appDelegate.googleAuthFlow = flow
            return promise
        }.then { authState -> Promise<Void> in
            self._authState = authState
            return self.refreshUser()
        }.then { _ -> Void in
            self._authState!.save(self.googleAuthStateStorage!)
        }
    }
    
    /// A helper function to refresh/synchronize self.user
    private func refreshUser() -> Promise<Void> {
        return self.token.then { token -> Promise<Void> in
            self.request("https://www.googleapis.com/plus/v1/people/me",
                         method: .get,
                         parameters: nil).then { json -> Void in
                let ans = UserModel()
                ans.parse(json)
                let realm = self.realmProvider.realm()
                try! realm.write {
                    realm.add(ans, update: true)
                }
                self.user = ans
            }
        }
    }
    
    /// This function will ensure the user is logged in.
    /// But rest assured, it will only call login() when necessary.
    func ensureLogin(presenter: UIViewController) -> Promise<Void> {
        guard let storagePath = googleAuthStateStorage else {
            return self.login(presenter: presenter)
        }
        self._authState = OIDAuthState.load(storagePath)
        guard let authState = self._authState else {
            return self.login(presenter: presenter)
        }
        return authState.performRefresh().asVoid().recover {err -> Promise<Void> in
            debugPrint("Failed to refresh access token. Reason: ", err)
            return self.login(presenter: presenter)
        }
    }
    
    func logout() {
        self._authState = nil
        if let storagePath = googleAuthStateStorage {
            try? FileManager.default.removeItem(atPath: storagePath)
        }
        guard let user = self.user else {
            return
        }
        let realm = realmProvider.realm()
        try? realm.write {
            realm.delete(user)
        }
    }
    
    var isLoggedIn : Bool {
        get {
            return _authState != nil
        }
    }
    
    var token : Promise<String> {
        guard let authState = self._authState else {
            return Promise<String>(error: GoogleError.NotLoggedIn)
        }
        return authState.performRefresh() .then { (token ,id) -> String in
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
    
    /// Please refer to documentation of protocol: "AbstractHTTPClient"
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
