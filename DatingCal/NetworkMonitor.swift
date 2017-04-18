//
//  NetworkMonitor.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/18/17.
//
//

import Foundation
import ReachabilitySwift

/// This class monitors the network reachability.
/// It calls GoogleCalendar and other APIs to notify changes.
class NetworkMonitor {
    let reachability = Reachability()!
    
    init() {
        self.reachability.whenReachable = { status in
            DispatchQueue.main.async {
                print("Network is reachable")
            }
        }
        self.reachability.whenUnreachable = { status in
            DispatchQueue.main.async {
                print("Network is NOT reachable")
            }
        }
        
        try! reachability.startNotifier()
    }
}
