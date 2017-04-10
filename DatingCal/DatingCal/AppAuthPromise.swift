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

/// OIDPromise: wrap OID* classes in promises.
class OIDPromise {
    
    var issuer : URL
    var config : OIDServiceConfiguration?
    
    init(issuer: URL) {
        self.issuer = issuer
    }
    
    private func generateCallback<T>(_ fulfill : @escaping (T) -> Void, _ reject : @escaping (Error) -> Void)  -> ((T?,Error?)->Void) {
        return { _ans, _err in
            if let err = _err {
                reject(err)
            } else {
                fulfill(_ans!)
            }
        }
    }
    
    func getConfigurations() -> Promise<OIDServiceConfiguration> {
        return Promise<OIDServiceConfiguration> { fulfill, reject in
            if let config = self.config {
                fulfill(config)
            } else {
                OIDAuthorizationService.discoverConfiguration(forIssuer: issuer, completion: generateCallback(fulfill, reject))
            }
        }.then{ config -> OIDServiceConfiguration in
            self.config = config
            return config
        }
    }
    
    func authState(request: OIDAuthorizationRequest, presenter: UIViewController) -> (OIDAuthorizationFlowSession, Promise<OIDAuthState>) {
        let (promise, fulfill, reject) = Promise<OIDAuthState>.pending()
        let session = OIDAuthState.authState(byPresenting: request, presenting: presenter, callback: generateCallback(fulfill, reject))

        return (session, promise)
    }
}
