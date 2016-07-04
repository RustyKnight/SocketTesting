//
//  AlertUtils.swift
//  Cioffi
//
//  Created by Shane Whitehead on 11/05/2016.
//  Copyright © 2016 Beam Communications. All rights reserved.
//

import UIKit

/**
 A handler for UIAlert actions based on the action identifier
 */
public protocol AlertActionHandler {
    /**
     Is called in response to the user responding to a notification alert of some kind.
     */
    func handleAlertAction(forApplication application: UIApplication, withIdentifier: String, forLocalNotification: UILocalNotification)
}

/**
 A simplified builder for building a `UIAlertController` from a `UILocalNotification`
 
 This takes the information from the notification and based on the category identifier, builds the actions for the controller,
 each action is then provided a handler which calls the associated delegate, passing to the information for the selected
 action
 */
public class AlertBuilder {

    /**
     Builds a UIAlertController from the `UILocalNotification` and `UIUserNotificationCatagory` information from the application.
     
     When the user selects a action, the `AlertActionHandler` is notified with the identifier for the given action
     
     - Parameter application: The `UIApplication` at the core of the notification
     - Parameter fromLocalNotification: The `UILocalNotification` which is been raised
     - Parameter withActionHandler: The `AlertActionHandler` to be notified when a user selects a action
     
     - Returns: A `UIAlertController` configured from the `UILocalNotification` and `UIApplication` parameters
     */
    public class func buildAlertController(forApplication application: UIApplication,
                                           fromLocalNotification notification: UILocalNotification,
                                           withActionHandler alertActionHandler: AlertActionHandler) -> UIAlertController {

        let alert = UIAlertController(title: notification.alertTitle, message: notification.alertBody, preferredStyle: .alert)
        // Sorry of the mess, I will try and walk you through it...
        // The basic idea is to try and make as much use of the UILocalNotifiction API as we can...
        // This represents a list of UIAlertAction's which will be configured with the alert
        var actions: [UIAlertAction] = []
        // Does the notification have a UIUserNotificationCategory identifier, if it does
        // we need to build the actions for it
        if let categoryIdentifier = notification.category {
            // This was a guard, but wouldn't let me break out
            // Does the application have any UserNotificationSettings actually configured?
            // Does the UIUserNotificationSettings actually have any categories ... be nice if
            // could return an empty set :P
            if let settings = application.currentUserNotificationSettings(),
                let categories = settings.categories {
                // This is the instance of UIUserNotificationCategory we will use to configure the
                // actions with if it's found (yes, it use to be a for-loop :P)
                let alertCategory = categories.filter({ $0.identifier == categoryIdentifier }).first

                // If we have a category and that category has UIUserNotificationAction for the .Default context
                if let alertCategory = alertCategory, let userActions = alertCategory.actions(for: .default) {
                    for userAction in userActions {
                        // We only accept UIUserNotificationAction which are configured with an identifier
                        if let identifier = userAction.identifier {
                            // Create an ActionItem to actually handle the UIAlertAction
                            // Okay, probably a few dozen ways this could have been done, but I wanted to
                            // maintain some level of context over it, please, this is a large enough
                            // mess as is :P
                            let actionItem = AlertActionItem(actionHandler: alertActionHandler,
                                                             application: application,
                                                             identifier: identifier,
                                                             notification: notification)
                            // Make the UIAlertAction
                            let action = UIAlertAction(title: userAction.title,
                                                       style: userAction.isDestructive ?
                                                                    UIAlertActionStyle.destructive :
                                                                    UIAlertActionStyle.default,
                                                       handler: actionItem.handleAction)
                            // Add it to our list...
                            actions.append(action)
                        } else {
                            log(error: "Notification raised with category identifier" +
                                " \(categoryIdentifier), but UIUserNotificationAction identifier is undefined")
                        }
                    }
                } else {
                    log(error: "Notification raised with category identifier" +
                        " \(categoryIdentifier), but no UIUserNotificationCategory with matching identifer was found" +
                        " or no UserNotificationAction's for context:.Default were found")
                }
            } else {
                log(error: "Notification raised with category identifier " +
                    "\(categoryIdentifier), but UIUserNotificationSettings/UINotificationCategory is not configured")
            }
        }
        // If we have no other actions, add "Ok"
        if actions.count == 0 {
            actions.append(UIAlertAction(
                title: "Ok",
                style: UIAlertActionStyle.default,
                handler: {(action: UIAlertAction!) in}))
        }

        for action in actions {
            alert.addAction(action)
        }
        return alert
    }

}

/**
 Defines a simple struct which maintains context over the information we need in order to
 call the `ErrorDelegate`'s `handleActionWithIdentifer` method
 */
public struct AlertActionItem {
    let actionHandler: AlertActionHandler
    let application: UIApplication
    let identifier: String
    let notification: UILocalNotification

    func handleAction(action: UIAlertAction) {
        actionHandler.handleAlertAction(forApplication: application, withIdentifier: identifier, forLocalNotification: notification)
    }
}
