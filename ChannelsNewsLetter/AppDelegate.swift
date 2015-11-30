//
//  AppDelegate.swift
//  ChannelsNewsLetter
//
//  Created by Prashanta Kumar Bose on 25/11/2015.
//  Copyright © 2015 Prashanta Kumar Bose. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = GAILogLevel.Verbose  // remove before app release
    
//        let firstAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
//        firstAction.identifier  = "First_Action"
//        firstAction.title = "First Action"
//        
//        firstAction.activationMode = UIUserNotificationActivationMode.Background
//        firstAction.destructive = true
//        firstAction.authenticationRequired = false
//        
//        let secondAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
//        secondAction.identifier  = "Second_Action"
//        secondAction.title = "Second Action"
//        
//        secondAction.activationMode = UIUserNotificationActivationMode.Foreground
//        secondAction.destructive = false
//        secondAction.authenticationRequired = false
//        
//        let thirdAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
//        thirdAction.identifier  = "Third_Action"
//        thirdAction.title = "Third Action"
//        
//        thirdAction.activationMode = UIUserNotificationActivationMode.Background
//        thirdAction.destructive = false
//        thirdAction.authenticationRequired = false
//        
//        //category
//        
//        let FirstCategory:UIMutableUserNotificationCategory = UIMutableUserNotificationCategory()
//        FirstCategory.identifier = "First_Category"
//        
//        let DefaultActions:NSArray = [firstAction, secondAction, thirdAction]
//        let MinimalActions:NSArray = [firstAction, secondAction]
//        
//        FirstCategory.setActions(DefaultActions as? [UIUserNotificationAction], forContext: UIUserNotificationActionContext.Default)
//        FirstCategory.setActions(MinimalActions as? [UIUserNotificationAction], forContext: UIUserNotificationActionContext.Minimal)
//        
//        let categories:NSSet = NSSet(object: FirstCategory)
//        
//        
//        let notificationTypes: UIUserNotificationType = UIUserNotificationType.Alert; UIUserNotificationType.Badge
//        let NotiSettings : UIUserNotificationSettings = UIUserNotificationSettings(forTypes: notificationTypes, categories: categories as? Set<UIUserNotificationCategory>)
//        UIApplication.sharedApplication().registerUserNotificationSettings(NotiSettings)
//        //ACTIONS
        
        
        return true
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


}

