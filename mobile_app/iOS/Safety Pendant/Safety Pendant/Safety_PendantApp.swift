//
//  Safety_PendantApp.swift
//  Safety Pendant
//
//  Created by ANDRE on 2026-01-26.
//

import SwiftUI
import Firebase //Main Firebase SDK for initialization
import FirebaseMessaging
import UserNotifications

@main
//Application entry point
struct Safety_PendantApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
// AppDelegate handles FCM token + notification setup
class AppDelegate: NSObject, UIApplicationDelegate,
                   UNUserNotificationCenterDelegate,
                   MessagingDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        
        // Set delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        return true
    }
    
    // Called when APNs gives us a device token — pass it to FCM
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // Called whenever FCM gives us a fresh token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM Token: \(token)")
        
        // Save to Firestore immediately
        AuthManager.shared.saveFCMToken(token)
    }
    
    // Show notification banner even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                 willPresent notification: UNNotification,
                                 withCompletionHandler completionHandler:
                                 @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
