//
//  AsyncTests.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/18/17.
//
//

import Foundation
import XCTest

class AsyncTests : XCTestCase {
    
    var isFinished = false
    
    override func setUp() {
        super.setUp()
        isFinished = false
    }
    
    override func tearDown() {
        super.tearDown()
        
        /// Wait until the current test method is finished
        while !isFinished {
            RunLoop.current.run(mode: .defaultRunLoopMode, before: .distantFuture)
        }
    }
    
    /// Notify that the current test method has finished execution
    func finishTest() {
        isFinished = true
    }
}
