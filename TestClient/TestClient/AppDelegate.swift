//
//  AppDelegate.swift
//  TestClient
//
//  Created by Shane Whitehead on 30/06/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import UIKit
import UserNotifications

extension UIApplicationState: CustomDebugStringConvertible {

    public var debugDescription: String {
        var value = "Unknown"
        switch self {
        case active:
            value = "Active (\(rawValue))"
        case inactive:
            value = "Inactive (\(rawValue))"
        case background:
            value = "Background (\(rawValue))"
        }
        return "[UIApplicationState]: \(value)"
    }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
        NotificationService.instance.register()
		return true
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
//        UIBackgroundTaskIdentifier myLongTask;
//        myLongTask = [[UIApplicationsharedApplication]
//            beginBackgroundTaskWithExpirationHandler:^{
//            // If you're worried about exceeding 10 minutes, handle it here
//            }];
//        [[UIApplication sharedApplication] endBackgroundTask:myLongTask];
//        BackgroundTaskManager.instance.start()
        let startDate = Date()
        AudioBackgroundManager.instance.start(with: 10.0) {
            let time = Date().timeIntervalSince(startDate)
            let formatter = DateComponentsFormatter()

            formatter.unitsStyle = .full
            formatter.allowedUnits = [Calendar.Unit.second, Calendar.Unit.minute]

            log(info: "In the background for \(formatter.string(from: time) ?? "?")")
        }
    }

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
//        BackgroundTaskManager.instance.stop()
        AudioBackgroundManager.instance.stop()
	}

}

extension AppDelegate: AlertActionHandler {
    @objc(application:didReceiveLocalNotification:)
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        didReceive(notification, for: application)
    }

    func didReceive(_ notification: UILocalNotification, `for` application: UIApplication) {
        log(info: "\(application.applicationState.debugDescription)")

        guard let userInfo = notification.userInfo else {
            return
        }
        guard let isNotificationService = userInfo[NotificationServicePayloadKey.notificationService] as? Bool else {
            return
        }
        if isNotificationService {
            let alert = AlertBuilder.buildAlertController(forApplication: application,
                                                          fromLocalNotification: notification,
                                                          withActionHandler: self)

            var topController: UIViewController = (application.keyWindow?.rootViewController)!

            while topController.presentedViewController != nil {
                topController = topController.presentedViewController!
            }

            topController.present(alert, animated: true, completion: nil)
        }
    }

    func handleAlertAction(forApplication application: UIApplication,
                           withIdentifier identifier: String,
                           forLocalNotification notification: UILocalNotification) {
        // We could handle it here, but the fact is, the delegate method will be called if the
        // notification occured while we were in the background, so we might as well let it handle it
        self.application(application, handleActionWithIdentifier: identifier, for: notification) { /*NOOP*/ }
    }

    @objc(application:handleActionWithIdentifier:forLocalNotification:completionHandler:)
    func application(_ application: UIApplication,
                     handleActionWithIdentifier identifier: String?,
                     for notification: UILocalNotification,
                     completionHandler: () -> Void) {
        defer {
            completionHandler()
        }
        // If the application is the background, this method will be called directly if the user
        // clicks one of the available "actions"

        log(info: "\(application.applicationState.debugDescription)")
        log(info: "identifier \(identifier)")

        // Without the identifier, it's impossible to know what to handle. This might change in the future as the userInfo payload
        // might provide the information required to handle it
        guard let identifer = identifier else {
            return
        }
        guard let userInfo = notification.userInfo else {
            return
        }
        guard let key = userInfo[NotificationServicePayloadKey.actionHandler] as? String else {
            return
        }
        guard let actionHandler = NotificationService.instance.actionHandler(for: key) else {
            return
        }
        actionHandler.notificationServiceHandleAction(withIdentifer: identifer, withUserInfo: userInfo)
    }
}

