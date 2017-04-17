//
//  AbstractSession.swift
//  DatingCal
//
//  Created by Zhongzhi Yu on 4/16/17.
//
//

import Foundation
import PromiseKit
import AppAuth

protocol AbstractSession {
    var isLoggedIn : Bool { get }
    
    /// This function should always return the latest token
    /// If the user isn't logged in, the promise should fail.
    var token : Promise<String> { get }
    
    /// This function will ensure the user is logged in.
    /// But rest assured, it will only call login() when necessary.
    func ensureLogin(presenter: UIViewController) -> Promise<Void>
    
    func logout() 
    
}
