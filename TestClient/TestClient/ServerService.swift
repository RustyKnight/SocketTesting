//
//  ServerService.swift
//  TestClient
//
//  Created by Shane Whitehead on 2/07/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import UIKit
import CocoaAsyncSocket

class ServerService {
	
	static let ServerConnectedNotification: NSNotification.Name = NSNotification.Name("Server.connected")
	static let ServerDisconnectedNotification: NSNotification.Name = NSNotification.Name("Server.disconnected")
	
	static let urlKey = "Server.url"
	static let hostKey = "Server.host"
	static let errorKey = "Server.error"

	static let `default`: ServerService = ServerService()
	
	internal let socket: GCDAsyncSocket = GCDAsyncSocket()
	
	init() {
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

extension ServerService: GCDAsyncSocketDelegate {
	func socket(_ sock: GCDAsyncSocket!, didConnectTo url: URL!) {
		DispatchQueue.main.async {
			log(info: "didConnectTo url \(url)")
			let userInfo: [NSObject:AnyObject] = [ServerService.urlKey: url]
			NotificationCenter.default().post(name: ServerService.ServerConnectedNotification,
			                                  object: self,
			                                  userInfo: userInfo)
		}
	}
	
	func socket(_ sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
		DispatchQueue.main.async { 
			log(info: "didConnectTo host \(host)")
			let userInfo: [NSObject:AnyObject] = [ServerService.hostKey: host]
			NotificationCenter.default().post(name: ServerService.ServerConnectedNotification,
			                                  object: self,
			                                  userInfo: userInfo)
		}
	}
	
	func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: NSError!) {
		DispatchQueue.main.async {
			log(info: "didDisconnect with \(err)")
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
		
	}
	
	func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
		
	}
	
}
