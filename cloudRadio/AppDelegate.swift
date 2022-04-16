//
//  AppDelegate.swift
//  CustomSideMenuiOSExample
//
//  Created by John Codeos on 2/7/21.
//

import UIKit
import YoutubeKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        YoutubeKit.shared.setAPIKey("AIzaSyC-8Ut8ITfm9KKHE-8-5pre5CzeStgUC-w")
        
        registerforDeviceLockNotification()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
           
        // 세로방향 고정
        return UIInterfaceOrientationMask.portrait
    }
    
    func registerforDeviceLockNotification() {
        //Screen lock notifications
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),     //center
            Unmanaged.passUnretained(self).toOpaque(),     // observer
            displayStatusChangedCallback,     // callback
            "com.apple.springboard.lockcomplete" as CFString,     // event name
            nil,     // object
            .deliverImmediately)
    }
    
    private let displayStatusChangedCallback: CFNotificationCallback = { _, cfObserver, cfName, _, _ in
        guard let lockState = cfName?.rawValue as String? else {return}
        if (lockState == "com.apple.springboard.lockcomplete") {
            Log.print("DEVICE LOCKED")
            CloudRadioShareValues.IsLockScreen = true
            CloudRadioShareValues.LockedPlay = false
        } else {
            Log.print("LOCK STATUS CHANGED")
            CloudRadioShareValues.IsLockScreen = false
        }
    }
}

