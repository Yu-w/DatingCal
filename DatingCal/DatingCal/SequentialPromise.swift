//
//  PromiseWrappers.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/18/17.
//
//

import Foundation
import PromiseKit

class SequentialPromise<T> {
    var currPromise : Promise<T>?
    
    /// If there is already another task going on, make this
    ///   task run after that one.
    func appendToRun(_ task: @escaping () -> Promise<T>) -> Promise<T> {
        guard let prevPromise = currPromise else {
            currPromise = task()
            return currPromise!
        }
        currPromise = prevPromise.then { _ -> Promise<T> in
            return task()
        }
        return currPromise!
    }
    
    /// If there is already another task going on, simply cancle
    ///    this task.
    func neverAppend(_ task: @escaping () -> Promise<T>) -> Promise<T> {
        if let prevPromise = currPromise {
            return prevPromise
        }
        currPromise = task().then { x -> T in
            self.currPromise = nil
            return x
        }
        return currPromise!
    }
    
}
