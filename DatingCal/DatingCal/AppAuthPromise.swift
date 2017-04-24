//
//  AppAuthPromise.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/10/17.
//
//

import Foundation
import AppAuth
import PromiseKit

/// These are information about Google API
fileprivate let kScopes : [String]? = [
    "https://www.googleapis.com/auth/calendar",         // Manage calendars
    "https://www.googleapis.com/auth/plus.me"           // Get unique user ID
]
fileprivate let kRedirectURI : URL = URL(string: "cs242.datingcal:/oauth2redirect/google")!
fileprivate let kClientId = "674497672844-d33bqapee8lm5l90l021sml0nsbvu3qp.apps.googleusercontent.com"
fileprivate let kIssuer = URL(string: "https://accounts.google.com")!

/// This is a helper function to generate a callback function that complies with PromiseKit
fileprivate func generateCallback<T>(_ fulfill : @escaping (T) -> Void, _ reject : @escaping (Error) -> Void)  -> ((T?,Error?)->Void) {
    return { _ans, _err in
        if let err = _err {
            reject(err)
        } else {
            fulfill(_ans!)
        }
    }
}


extension OIDAuthorizationService {
    private static var cachedConfig: OIDServiceConfiguration?
    
    static func getConfigurations(issuer: URL = kIssuer) -> Promise<OIDServiceConfiguration> {
        return Promise<OIDServiceConfiguration> { fulfill, reject in
            if let config = cachedConfig {
                fulfill(config)
            } else {
                OIDAuthorizationService.discoverConfiguration(forIssuer: issuer, completion: generateCallback(fulfill, reject))
            }
        }.then{ config -> OIDServiceConfiguration in
            cachedConfig = config
            return config
        }
    }
}

extension OIDAuthState {
    
    typealias AuthStateResult = (OIDAuthorizationFlowSession, Promise<OIDAuthState>)
    
    /// Start login to any API (not just Google)
    static func authState(request: OIDAuthorizationRequest, presenter: UIViewController) -> AuthStateResult {
        let (promise, fulfill, reject) = Promise<OIDAuthState>.pending()
        let session = OIDAuthState.authState(byPresenting: request, presenting: presenter, callback: generateCallback(fulfill, reject))

        return (session, promise)
    }
    
    /// Start login with the default API endpoints
    static func startLogin(_ config: OIDServiceConfiguration, _ presenter: UIViewController) -> AuthStateResult {
        let request = OIDAuthorizationRequest(configuration: config
            , clientId: kClientId, clientSecret: nil
            , scopes: kScopes, redirectURL: kRedirectURI
            , responseType: OIDResponseTypeCode, additionalParameters: nil)
        
        return OIDAuthState.authState(request: request, presenter: presenter)
    }
    
    /// Refresh user token and id from OAuth API
    func performRefresh() -> Promise<(String?, String?)> {
        return Promise { fulfill, reject in
            self.performAction(freshTokens: { token,id,err in
                if let err = err {
                    reject(err)
                }
                fulfill((token, id))
            })
        }
    }
    
    /// Save login state to hard drive
    func save(_ toFile: String) {
        NSKeyedArchiver.archiveRootObject(self, toFile: toFile)
    }
    
    /// Load login state from hard drive
    static func load(_ toFile: String) -> OIDAuthState? {
        guard let data = NSData(contentsOfFile: toFile) else {
            return nil
        }
        let unarchiver = NSKeyedUnarchiver(forReadingWith: data as Data)
        unarchiver.requiresSecureCoding = false
        return unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? OIDAuthState
    }
}
