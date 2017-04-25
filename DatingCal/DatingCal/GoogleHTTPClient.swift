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
    
    /// This variable can only be used by our class.
    ///    It's an abstraction.
    /// We have to fetch a new UserModel every time
    ///    because otherwise, realm will require threadsafe references
    private var user : UserModel? {
        get {
            let realm = realmProvider.realm()
            if let id = _userId,
                let user = realm.objects(UserModel.self).filter({u in u.id==id}).first {
                return user
            } else {
                let primary = realm.objects(UserModel.self).filter({u in u.isPrimary}).first
                _userId = primary?.id
                return primary
            }
        }
        
        set {
            _userId = newValue?.id
        }
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
            self._authState!.save(self.user!.authStorage)
        }
    }
    
    /// A helper function to refresh/synchronize self.user
    ///   Note that this will set current user as the default user
    private func refreshUser() -> Promise<Void> {
        return self.token.then { token -> Promise<Void> in
            self.request("https://www.googleapis.com/plus/v1/people/me",
                         method: .get,
                         parameters: nil).then { json -> Void in
                let ans = UserModel()
                ans.parse(json)
                let realm = self.realmProvider.realm()
                try! realm.write {
                    ans.isPrimary = true
                    let primaries = realm.objects(UserModel.self).filter({x in x.isPrimary})
                    for primary in primaries {
                        primary.isPrimary = false
                    }
                    realm.add(ans, update: true)
                }
                self.user = ans
            }
        }
    }
    
    /// This function will ensure the user is logged in.
    /// But rest assured, it will only call login() when necessary.
    func ensureLogin(presenter: UIViewController) -> Promise<Void> {
        guard let storagePath = self.user?.authStorage else {
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
    
    /// Change current user to another user
    /// It returns a promise that fulfills when credentials are ready
    /// :param presenter: Necessary in case google wants to display a login page
    func changeUser(_ toUser: UserModel, _ presenter: UIViewController) -> Promise<Void> {
        self.user = toUser
        self._authState = nil
        return self.ensureLogin(presenter: presenter).then { _ -> Void in
            let realm = self.realmProvider.realm()
            try! realm.write {
                self.user!.isPrimary = true
                let primaries = realm.objects(UserModel.self).filter({x in x.isPrimary})
                for primary in primaries {
                    primary.isPrimary = false
                }
            }
        }
    }
    
    /// Login to a completely new account, and
    ///  replace current user with this account.
    /// :param presenter: Necessary because google wants to display a login page
    func acceptNewUser(_ presenter: UIViewController) -> Promise<Void> {
        self._authState = nil
        return self.login(presenter: presenter)
    }
    
    /// Returns the primary user
    ///   This is the account where we create new events.
    func getPrimaryUser() -> UserModel? {
        return self.user
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
    
    /// Please refer to documentation of protocol: "AbstractHTTPClient"
    func request(_ url: URLConvertible,
                 method: HTTPMethod,
                 parameters: Parameters?) -> Promise<JSON> {
        return self.token.then { _token in
            let headers : HTTPHeaders = ["Authorization":"Bearer " + _token]
            let encoding : ParameterEncoding = (parameters==nil||method==(.get)) ? URLEncoding.default : JSONEncoding.default
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
