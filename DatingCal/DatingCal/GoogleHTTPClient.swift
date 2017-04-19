//
//  RealHTTPClient.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/16/17.
//
//

import Foundation
import PromiseKit
import Alamofire
import SwiftyJSON

class GoogleHTTPClient : AbstractHTTPClient {
    var googleSession : AbstractSession
    
    /// accessToken: the authorization token for this user, returned by Google OAuth2 protocol
    init(_ googleSession: AbstractSession) {
        self.googleSession = googleSession
    }
    
    func getHeaders() -> Promise<HTTPHeaders> {
        return googleSession.token.then { token -> HTTPHeaders in
            ["Authorization":"Bearer " + token]
        }
    }
    
    func request(_ url: URLConvertible,
                 method: HTTPMethod,
                 parameters: Parameters?) -> Promise<JSON> {
        return getHeaders().then { headers in
            let encoding : ParameterEncoding = parameters==nil ? URLEncoding.default : JSONEncoding.default
            let requested = Alamofire.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
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
    
    var userId : Promise<String> {
        get {
            return self.googleSession.token.then { token -> Promise<String> in
                self.request("https://www.googleapis.com/plus/v1/people/me",
                             method: .get,
                             parameters: nil).then { json -> String in
                    json["id"].string!
                }
            }
        }
    }
}
