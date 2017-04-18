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
import RealmSwift
@testable import DatingCal

enum FakeHTTPError : Error {
    case ResultNotSet
    case InvalidOperation
}

class FakeHTTPClient : AbstractHTTPClient {
    
    private var handler : ((_ url: URLConvertible, _ method: HTTPMethod, _ parameters: Parameters?) -> Promise<JSON>)?
    
    func setHandler(_ handler: @escaping ((_ url: URLConvertible, _ method: HTTPMethod, _ parameters: Parameters?)->Promise<JSON>)) {
        self.handler = handler
    }
    
    func request(_ url: URLConvertible, method: HTTPMethod, parameters: Parameters?) -> Promise<JSON> {
        guard let handler = self.handler else {
            return Promise { _, reject in reject(FakeHTTPError.ResultNotSet) }
        }
        return handler(url, method, parameters)
    }
    
}

class FakeRealmProvider : AbstractRealmProvider {
    func realm() -> Realm {
        let config = Realm.Configuration(
            fileURL: nil,
            inMemoryIdentifier: "test",
            syncConfiguration: nil
        )
        return try! Realm(configuration: config)
    }
}
