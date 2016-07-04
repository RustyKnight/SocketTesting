//
//  NotificationService.swift
//  TestSIP
//
//  Created by Shane Whitehead on 4/07/2016.
//  Copyright © 2016 Shane Whitehead. All rights reserved.
//

import UIKit

protocol NotificationServiceActionHandler: AnyObject {
    func notificationServiceHandleAction(withIdentifer identifer: String, withUserInfo: [NSObject: AnyObject])
}

struct NotificationServicePayloadKey {
    static let actionHandler = "NotificationServiceKey.actionHandler"
    static let notificationService = "NotificationServiceKey.notificationService"
}

struct UserLocalNotificationCategoryIdentifier {
    static let retryCancel: String = "UserLocalNotificationCategory.retyCancel"
    static let acceptCancel: String = "UserLocalNotificationCategory.acceptCancel"
}


class NotificationService {

    static let instance = NotificationService()

    struct Strings {
        static let alertActionRetry: String = "Retry"
        static let alertActionCancel: String = "Cancel"
        static let alertActionAccept: String = "Accept"
    }

    struct UserLocalNotificationActionIdentifier {
        static let retry: String = "UserLocalNotificationActionIdentifer.retry"
        static let accept: String = "UserLocalNotificationActionIdentifer.accept"
        static let cancel: String = "UserLocalNotificationCategory.cancel"
    }

    lazy var catagories: Set<UIUserNotificationCategory>? = {

        let retryAction = UserNotificationActionBuilder()
            .with(title: Strings.alertActionRetry)
            .with(identifier: UserLocalNotificationActionIdentifier.retry)
            .build()
        let cancelAction = UserNotificationActionBuilder()
            .with(title: Strings.alertActionCancel)
            .with(activationMode: .background)
            .with(identifier: UserLocalNotificationActionIdentifier.cancel)
            .build()
        let acceptAction = UserNotificationActionBuilder()
            .with(title: Strings.alertActionAccept)
            .with(identifier: UserLocalNotificationActionIdentifier.accept)
            .build()

        let retryCancelCategory = UIMutableUserNotificationCategory()
        retryCancelCategory.identifier = UserLocalNotificationCategoryIdentifier.retryCancel
        retryCancelCategory.setActions([retryAction, cancelAction], for: .default)
        retryCancelCategory.setActions([retryAction, cancelAction], for: .minimal)

        let acceptCancelCategory = UIMutableUserNotificationCategory()
        acceptCancelCategory.identifier = UserLocalNotificationCategoryIdentifier.acceptCancel
        acceptCancelCategory.setActions([acceptAction, cancelAction], for: .default)
        acceptCancelCategory.setActions([acceptAction, cancelAction], for: .minimal)

        return NSSet(objects: retryCancelCategory, acceptCancelCategory) as? Set<UIUserNotificationCategory>
    }()

    var actionHandlerRegistry: [String: NotificationServiceActionHandler] = [:]

    func register() {
        let notificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound],
                                                              categories: NotificationService.instance.catagories)
        UIApplication.shared().registerUserNotificationSettings(notificationSettings)
    }

    func actionHandler(`for` key: String, remove: Bool = true) -> NotificationServiceActionHandler? {
        var handler: NotificationServiceActionHandler?
        if let reference = actionHandlerRegistry[key] {
            handler = reference
            if remove {
                actionHandlerRegistry[key] = nil
            }
        }
        return handler
    }
    func showNotification(withTitle title: String,
                          andBody body: String,
                          after: TimeInterval) {
        showNotification(withTitle: title,
                         andBody: body,
                         withAlertAction: nil,
                         andCategory: nil,
                         andSound: nil,
                         andUserInfo: nil,
                         andAfter: after,
                         andHandleActionWith: nil)
    }

    func showNotification(withTitle title: String,
                          andBody body: String,
                          withAlertAction alertAction: String? = nil,
                          andCategory category: String? = nil,
                          andSound sound: String? = nil,
                          andUserInfo userInfo: [NSObject: AnyObject]? = nil,
                          andAfter: TimeInterval? = nil,
                          andHandleActionWith handler: NotificationServiceActionHandler? = nil) {

        var expandedInfo: [NSObject:AnyObject] = [:]
        if let userInfo = userInfo {
            // See Operators.swift
            expandedInfo += userInfo
        }

        if let handler = handler {
            let uuid = NSUUID().uuidString
            actionHandlerRegistry[uuid] = handler
            expandedInfo[NotificationServicePayloadKey.actionHandler] = uuid
        }
        expandedInfo[NotificationServicePayloadKey.notificationService] = true

        let notification = UILocalNotification()
        notification.alertTitle = title
        notification.alertBody = body
        notification.alertAction = alertAction
        notification.hasAction = alertAction != nil
        notification.userInfo = expandedInfo
        notification.category = category
        notification.soundName = sound

        if let after = andAfter {
            notification.fireDate = Date(timeIntervalSinceNow: after)
            UIApplication.shared().scheduleLocalNotification(notification)
        } else {
            log(info: "Present Local Notification Now")
            UIApplication.shared().presentLocalNotificationNow(notification)
        }
    }

}

class UserNotificationActionBuilder {
    var identifer: String?
    var title: String?
    var activationMode: UIUserNotificationActivationMode = .foreground
    var authenticationRequired: Bool = false
    var destructive: Bool = false
    var behavior: UIUserNotificationActionBehavior = .default
    var parameters: [NSObject: AnyObject] = [:]

    func with(identifier: String?) -> UserNotificationActionBuilder {
        self.identifer = identifier
        return self
    }

    func with(title: String?) -> UserNotificationActionBuilder {
        self.title = title
        return self
    }

    func with(activationMode value: UIUserNotificationActivationMode) -> UserNotificationActionBuilder {
        activationMode = value
        return self
    }

    func `is`(authenticationRequired value: Bool) -> UserNotificationActionBuilder {
        authenticationRequired = value
        return self
    }

    func `is`(destructive value: Bool) -> UserNotificationActionBuilder {
        destructive = value
        return self
    }

    func with(behavior value: UIUserNotificationActionBehavior) -> UserNotificationActionBuilder {
        behavior = value
        return self
    }

    func with(parameters value: [NSObject: AnyObject]) -> UserNotificationActionBuilder {
        parameters = value
        return self
    }

    func build() -> UIUserNotificationAction {
        let action = UIMutableUserNotificationAction()
        action.identifier = identifer
        action.title = title
        action.activationMode = activationMode
        action.isAuthenticationRequired = authenticationRequired
        action.isDestructive = destructive
        action.behavior = behavior
        action.parameters = parameters
        return action
    }
}
