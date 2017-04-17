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
