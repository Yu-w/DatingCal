//
//  AppDelegate.swift
//  DatingCal
//
//  Created by Wang Yu on 4/9/17.
//
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {

    var window: UIWindow?
    
    // -------------- GOOGLE LOGIN helpers --------------------
    
    func initGoogleSignIn() -> Bool {
        // Initialize Google sign-in
        var configErr: NSError?
        GGLContext.sharedInstance().configureWithError(&configErr)
        if(configErr != nil) {
            print("Error while configuring Google services");
            return false;
        }
        
        GIDSignIn.sharedInstance().delegate = self
        return true;
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError err: Error!) {
        if (err == nil) {
            print("Login: ", user)
        } else {
            print(err.localizedDescription)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user:GIDGoogleUser!, withError err: Error!) {
        if (err == nil) {
            print("Disconnect: ", user)
        } else {
            print(err.localizedDescription)
        }
    }
    
    // -------------- END OF GOOGLE LOGIN helpers --------------------

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return initGoogleSignIn()
    }
    
    func application(_ application: UIApplication, open openURL: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return GIDSignIn.sharedInstance().handle(
            openURL,
            sourceApplication: sourceApplication,
            annotation: annotation)
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

