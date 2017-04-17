//
//  FakeHTTPClient.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/16/17.
//
//

import Foundation
import PromiseKit
import SwiftyJSON
import Alamofire
@testable import DatingCal

class FakeHTTPClient : AbstractHTTPClient {
    
    let wantedResult : JSON
    
    init(_ wantedResult: JSON) {
        self.wantedResult = wantedResult
    }
    
    func request(_ url: URLConvertible, method: HTTPMethod, parameters: Parameters?) -> Promise<JSON> {
        return Promise { fulfill, _ in fulfill(wantedResult) }
    }
    
}
