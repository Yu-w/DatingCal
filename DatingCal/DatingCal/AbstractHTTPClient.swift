//
//  AbstractHTTPClient.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/16/17.
//
//

import Foundation
import Alamofire
import PromiseKit
import SwiftyJSON

protocol AbstractHTTPClient {
    
    init(_ session: AbstractSession)
    
    /// Wrap any JSON-based Alamofire request in a Promise
    /// Encoding method will be set to JSONEncoding.default
    /// (PromiseKit/Alamofire- isn't working...)
    func request(_ url: URLConvertible,
                 method: HTTPMethod,
                 parameters: Parameters?) -> Promise<JSON>
}
