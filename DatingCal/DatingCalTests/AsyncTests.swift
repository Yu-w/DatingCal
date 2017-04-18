//
//  AsyncTests.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/18/17.
//
//

import Foundation
import PromiseKit
import XCTest

class AsyncTests : XCTestCase {
    
    /// Complete a test case by waiting for a promise
    func testPromise<T>(_ promise: Promise<T>) {
        var isFinished = [false]
        promise.catch { err in
            XCTFail("Exception was thrown: " + err.localizedDescription)
        }.always {
            isFinished[0] = true
        }
        while !isFinished[0] {
            RunLoop.current.run(mode: .defaultRunLoopMode, before: .distantFuture)
        }
    }
}
