//
//  ServerService.swift
//  TestClient
//
//  Created by Shane Whitehead on 2/07/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import UIKit
import UserNotifications
import CocoaAsyncSocket

class ServerService: NSObject {
	
	static let ServerConnectedNotification: NSNotification.Name = NSNotification.Name("Server.connected")
	static let ServerDisconnectedNotification: NSNotification.Name = NSNotification.Name("Server.disconnected")

	static let ServerSentNotification: NSNotification.Name = NSNotification.Name("Server.sent")
	static let ServerRecivedNotification: NSNotification.Name = NSNotification.Name("Server.recived")
	
	static let urlKey = "Server.url"
	static let hostKey = "Server.host"
	static let errorKey = "Server.error"
	static let dataKey = "Server.data"

	static let `default`: ServerService = ServerService()
	
	internal let socket: GCDAsyncSocket = GCDAsyncSocket()
	
	internal var sentData: String?
	
	override init() {
	}
	
	var connected: Bool {
		return socket.isConnected
	}
	
	func connect(to host: String, port: UInt16) throws {
		if connected {
			disconnect()
		}
		socket.delegate = self
		socket.delegateQueue = DispatchQueue.global()
		try socket.connect(toHost: host, onPort: port)
	}
	
	func disconnect() {
		if connected {
			socket.disconnect()
			socket.delegate = nil
			socket.delegateQueue = nil
		}
	}
}

extension ServerService {
	
	func sendData() {
		if connected {
			let date = Date()
			let value = "\(date)"
			sentData = value
			socket.write(value.data(using: String.Encoding.utf8), withTimeout: 30.0, tag: 1)
		}
	}
	
}

extension ServerService: GCDAsyncSocketDelegate {
	
	func startReading() {
		socket.readData(withTimeout: -1, tag: 100)
	}
	
	func socket(_ sock: GCDAsyncSocket!, didConnectTo url: URL!) {
		sock.perform {
            log(info: "enableBackgroundingOnSocket \(sock.enableBackgroundingOnSocket())")
		}
		DispatchQueue.main.async {
			log(info: "didConnectTo url \(url)")
			let userInfo: [NSObject:AnyObject] = [ServerService.urlKey: url]
			NotificationCenter.default().post(name: ServerService.ServerConnectedNotification,
			                                  object: self,
			                                  userInfo: userInfo)
		}
	}
	
	func socket(_ sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        sock.perform {
            log(info: "enableBackgroundingOnSocket \(sock.enableBackgroundingOnSocket())")
        }
		DispatchQueue.main.async {
			log(info: "didConnectTo host \(host)")
			self.startReading()
			let userInfo: [NSObject:AnyObject] = [ServerService.hostKey: host]
			NotificationCenter.default().post(name: ServerService.ServerConnectedNotification,
			                                  object: self,
			                                  userInfo: userInfo)
		}
	}
	
	func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: NSError!) {
		DispatchQueue.main.async {
			log(info: "didDisconnect with \(err)")
			self.startReading()
			var userInfo: [NSObject:AnyObject] = [:]
			if let error = err {
				userInfo[ServerService.errorKey] = error
			}
			NotificationCenter.default().post(name: ServerService.ServerDisconnectedNotification,
			                                  object: self,
			                                  userInfo: userInfo)
		}
	}
	
	func socket(_ sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
		DispatchQueue.main.async {
			log(info: "Wrote \(self.sentData) with tag \(tag)")
			var userInfo: [NSObject:AnyObject] = [:]
			if let sentData = self.sentData {
				userInfo[ServerService.dataKey] = sentData
			}
			NotificationCenter.default().post(name: ServerService.ServerSentNotification,
			                                  object: self,
			                                  userInfo: userInfo)
		}
	}

	func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
		if let text = String(data: data, encoding: String.Encoding.utf8) {
			DispatchQueue.main.async {
				log(info: "Read with tag \(tag)")
				let userInfo: [NSObject:AnyObject] = [ServerService.dataKey:text]
				NotificationCenter.default().post(name: ServerService.ServerRecivedNotification,
				                                  object: self,
				                                  userInfo: userInfo)
			}
		} else {
			log(warning: "Failed to convert data to string")
		}
		self.startReading()
	}
	
}

extension ServerService: UNUserNotificationCenterDelegate {
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: () -> Void) {
		log(info: "didReceive")
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: (UNNotificationPresentationOptions) -> Void) {
		log(info: "willPresent")
	}
}
