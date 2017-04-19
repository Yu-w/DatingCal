//
//  AppDelegate.swift
//  DatingCal
//
//  Created by Wang Yu on 4/9/17.
//  Copyright © 2016 Yu Wang. All rights reserved.
//

import UIKit
import AppAuth
import PromiseKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let googleClient = GoogleHTTPClient()
    var googleAuthFlow: OIDAuthorizationFlowSession?
    
    lazy var googleCalendar : GoogleCalendar = { [unowned self] in
        return GoogleCalendar(self.googleClient, BusinessRealmProvider())
    }()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    // Accept token returned from Google through URL Scheme
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        debugPrint(url)
        if let flow = googleAuthFlow, flow.resumeAuthorizationFlow(with: url) {
            googleAuthFlow = nil
            return true
        } else {
            return false
        }
    }
    
    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        return true;
    }
    
    func doSynchronization(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        _ = NetworkMonitor.shared.replayCommand().then { hasNext -> Void in
            if(hasNext) {
                self.doSynchronization(completionHandler)
            }
        }.always {
            debugPrint("Sync finished")
            completionHandler(.newData)
        }
    }
    
    // Perform background refresh.
    // This is also our only method to detect change in network reachability.
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        debugPrint("Background refresh started")
        doSynchronization(completionHandler)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    var isSyncScheduled = false
    func scheduleSyncTimer() {
        if isSyncScheduled {
            return
        }
        isSyncScheduled = true
        Timer.scheduledTimer(withTimeInterval: 10, repeats: false, block: {_ in
            self.doSynchronization({ _ in
                self.isSyncScheduled = false
                self.scheduleSyncTimer()
            })
        })
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        self.scheduleSyncTimer()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

