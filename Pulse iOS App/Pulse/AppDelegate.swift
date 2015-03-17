//
//  AppDelegate.swift
//  Pulse
//
//  Created by Michael DeWitt on 10/26/14.
//  Copyright (c) 2014 Biomedical Engineering Design. All rights reserved.
//

import UIKit
import HealthKit

public protocol HKAccessProtocol: class {
    var healthStore: HKHealthStore? { get set }
}

let kClientId = "739218324274-bkm37s8in7r5dqoq5mmvgn2jgml2upq1.apps.googleusercontent.com"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    var healthStore = HKHealthStore()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        setUpHealthStoreForTabBarController()
        
        return true
    }
    
    func setUpHealthStoreForTabBarController() {
        if let tabBarController = window?.rootViewController as? UITabBarController {
        
            for controller in tabBarController.viewControllers! {
                
                let viewController: UIViewController
                if let nav = controller as? UINavigationController {
                    viewController = nav.topViewController
                }
                else {
                    viewController = controller as! UIViewController
                }
                
                if let vc = viewController as? HKAccessProtocol {
                    vc.healthStore = healthStore
                }
            }
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return GPPURLHandler.handleURL(url, sourceApplication: sourceApplication, annotation:annotation)
    }
}

