//
//  NetworkMonitor.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/18/17.
//
//

import Foundation
import PromiseKit
import ReachabilitySwift

/// This class handles connectivity issues encountered in promises,
///   and replays the actions when network is available again.
class NetworkMonitor {
    
    typealias Replayer = () -> Promise<Void>
    
    private init() {}
    static let shared = NetworkMonitor()
    
    var commandsToReplay : Array<Replayer> = Array()
    let lockQueue = DispatchQueue(label: "DatingCal.NetworkMonitor")
    
    /// This function should be called to examine any network error.
    ///   It finds out if we lost internet connection, and replay the
    ///   action later when there is connection.
    /// :param replayer: A function to replay the same command that
    ///   the failed promise was trying to execute.
    func handleNoInternet(_ replayer: @escaping Replayer) -> Bool {
        if(Reachability.init()!.currentReachabilityStatus != .notReachable) {
            return false
        }
        self.lockQueue.sync {
            self.commandsToReplay.append(replayer)
        }
        return true
    }
    
    /// Background refresh and timers should call this function
    ///    to replay a command.
    /// :return: Promise<Bool> where the boolean indicates whether
    ///    there is more commands to execute.
    func replayCommand() -> Promise<Bool> {
        return Promise(value: false).then(on: self.lockQueue, execute: { _ -> Promise<Bool> in
            guard let replayer = self.commandsToReplay.popLast() else {
                return Promise(value: false)
            }
            return replayer().then { _ -> Bool in
                return !self.commandsToReplay.isEmpty
            }.catch { err in
                self.handleNoInternet(replayer)
            }
        })
    }
    
    /// Similar to replayCommand(), but this will
    /// block the current thread.
    func replayCommandSync() -> Bool {
        var hasNext = [false]
        var isFinished = [false]
        _ = self.replayCommand().then { _hasNext -> Void in
            hasNext[0] = _hasNext
            isFinished[0] = true
        }
        while !isFinished[0] {
            RunLoop.current.run(mode: .defaultRunLoopMode, before: .distantFuture)
        }
        return hasNext[0]
    }
}
