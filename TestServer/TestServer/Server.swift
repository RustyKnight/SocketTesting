//
//  Server.swift
//  TestServer
//
//  Created by Shane Whitehead on 30/06/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class Server {
	
	static let dataKey = "Server.data"
	static let errorKey = "Server.error"
	
	static let dataWrittenNotification: NSNotification.Name = NSNotification.Name("Server.dataWritten")
	static let dataReadNotification: NSNotification.Name = NSNotification.Name("Server.dataRead")
	static let clientDisconnectedNotification: NSNotification.Name = NSNotification.Name("Server.clientDisconnecetd")
	static let clientConnectedNotification: NSNotification.Name = NSNotification.Name("Server.clientConnecetd")
	
	static let `default` = Server()
	
	internal let socket: GCDAsyncSocket
	internal var clientSocket: GCDAsyncSocket?
	
	internal let clientDelegate: ClientSocketDelegate = ClientSocketDelegate()
	
	internal var sentData: String?
	
	init() {
		socket = GCDAsyncSocket()
		socket.delegateQueue = DispatchQueue(label: "server-socket")
		socket.delegate = self
	}
	
	func start() throws {
		try socket.accept(onPort: 9090)
		log(info: "Server started")
	}
	
	func stop() {
			if let clientSocket = clientSocket {
				clientSocket.disconnect()
			}
			socket.disconnect()
			log(info: "Server stopped")
	}
	
	func sendData() {
		guard let clientSocket = clientSocket else {
			log(error: "No client connected")
			return
		}
		let value = "\(Date())"
		sentData = value
		clientSocket.write(value.data(using: String.Encoding.utf8), withTimeout: 30.0, tag: 1)
	}
	
	func clientDisconnected() {
		if let socket = clientSocket {
			socket.delegate = nil
		}
		clientSocket = nil
	}
	
}

extension Server: GCDAsyncSocketDelegate {
	
	func socket(_ sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
		if clientSocket == nil {
			log(info: "Client connected")
			if let clientSocket = clientSocket {
				clientSocket.disconnect()
				clientSocket.delegate = nil
			}
			clientSocket = newSocket
			clientSocket?.delegate = clientDelegate
			
			NotificationCenter.default().post(name: Server.clientConnectedNotification,
			                                  object: Server.default)
			
			clientSocket?.readData(withTimeout: -1, tag: 100)
		}
	}
	
	func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
		log(warning: "Server didRead data?")
	}
	
	func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: NSError!) {
		log(warning: "Server didDisconnect with \(err)")
	}
	
}

class ClientSocketDelegate: GCDAsyncSocketDelegate {
	
	func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
		log(info: "Client didRead with tag \(tag)")
		if let text = String(data: data, encoding: String.Encoding.utf8) {
			log(info: "Read \(text)")
			let userInfo: [NSObject:AnyObject] = [Server.dataKey:text]
			NotificationCenter.default().post(name: Server.dataReadNotification,
			                                  object: Server.default,
			                                  userInfo: userInfo)
			sock.readData(withTimeout: -1, tag: 100)
		}
	}
	
	func socket(_ sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
		log(info: "Client didWrite with \(tag)")
		if let sentData = Server.default.sentData {
			let userInfo: [NSObject: AnyObject] = [Server.dataKey: sentData]
			NotificationCenter.default().post(name: Server.dataWrittenNotification,
			                                  object: Server.default,
			                                  userInfo: userInfo)
		}
	}
	
	func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: NSError!) {
		log(info: "Client didDisconnect with \(err)")
		var userInfo: [NSObject:AnyObject] = [:]
		if let error = err {
				userInfo = [Server.dataKey:error]
		}
		Server.default.clientDisconnected()
		NotificationCenter.default().post(name: Server.clientDisconnectedNotification,
		                                  object: Server.default,
		                                  userInfo: userInfo)
	}
	
}
