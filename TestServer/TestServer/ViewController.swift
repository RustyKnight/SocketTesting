//
//  ViewController.swift
//  TestServer
//
//  Created by Shane Whitehead on 30/06/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
	
	@IBOutlet weak var serverStateSwitch: NSButton!
	@IBOutlet weak var clientNotConnectedLabel: NSTextField!
	@IBOutlet weak var clientConnectedLabel: NSTextField!
	
	@IBOutlet weak var timerLabel: NSTextField!
	@IBOutlet weak var timerSlider: NSSlider!
	
	@IBOutlet weak var dataRecievedLabel: NSTextField!
	@IBOutlet weak var dataSendLabel: NSTextField!
	
	@IBOutlet weak var sendDataButton: NSButton!
	
	@IBOutlet weak var sendRandomlyButton: NSButton!
	@IBOutlet weak var sendRegularlyButton: NSButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		clientConnectedLabel.isHidden = true
		sendDataButton.isEnabled = false
		
		updateTimeLabel()		
	}
	
	override func viewWillAppear() {
		super.viewWillAppear()
		
		NotificationCenter.default().addObserver(self,
		                                         selector: #selector(ViewController.clientDidConnect(notification:)),
		                                         name: Server.clientConnectedNotification,
		                                         object: nil)
		NotificationCenter.default().addObserver(self,
		                                         selector: #selector(ViewController.clientDidDisconnect(notification:)),
		                                         name: Server.clientDisconnectedNotification,
		                                         object: nil)
		NotificationCenter.default().addObserver(self,
		                                         selector: #selector(ViewController.didReadData(notification:)),
		                                         name: Server.dataReadNotification,
		                                         object: nil)
		NotificationCenter.default().addObserver(self,
		                                         selector: #selector(ViewController.didWriteData(notification:)),
		                                         name: Server.dataWrittenNotification,
		                                         object: nil)
	}
	
	override func viewWillDisappear() {
		super.viewWillDisappear()
		
		NotificationCenter.default().removeObserver(self,
		                                            name: Server.clientConnectedNotification,
		                                            object: nil)
		NotificationCenter.default().removeObserver(self,
		                                            name: Server.clientDisconnectedNotification,
		                                            object: nil)
		NotificationCenter.default().removeObserver(self,
		                                            name: Server.dataReadNotification,
		                                            object: nil)
		NotificationCenter.default().removeObserver(self,
		                                            name: Server.dataWrittenNotification,
		                                            object: nil)
	}

	override var representedObject: AnyObject? {
		didSet {
		// Update the view, if already loaded.
		}
	}
	
	@IBAction func serverStateChanged(_ sender: AnyObject) {
		if serverStateSwitch.state == NSOnState {
			log(info: "Attempting to start server")
			do {
				try Server.default.start()
			} catch let error {
				log(error: "\(error)")
			}
		} else if serverStateSwitch.state == NSOffState {
			log(info: "Attempting to stop server")
			Server.default.stop()
		}
	}
	
	var timeInterval: TimeInterval {
		return ((timerSlider.doubleValue / 100.0) * ((9 * 60) + 30)) + 30
	}
	
	func updateTimeLabel() {
		let time = timeInterval
		let formatter = DateComponentsFormatter()
		
		formatter.unitsStyle = .full
		formatter.allowedUnits = [Calendar.Unit.second, Calendar.Unit.minute]
		timerLabel.stringValue = formatter.string(from: time) ?? "?"
	}
	
	@IBAction func timerSliderChanged(_ sender: AnyObject) {
		updateTimeLabel()
	}
	
	@IBAction func sendTimingChanged(_ sender: NSButton) {
	}
	
	@IBAction func sendDataClicked(_ sender: AnyObject) {
		Server.default.sendData()
	}

}

extension ViewController {
	
	func did(connect: Bool) {
		DispatchQueue.main.async { 
			self.clientConnectedLabel.isHidden = !connect
			self.clientNotConnectedLabel.isHidden = connect
			
			self.sendDataButton.isEnabled = connect
		}
	}
	
	func clientDidConnect(notification: NSNotification!) {
		did(connect: true)
	}
	
	func clientDidDisconnect(notification: NSNotification!) {
		did(connect: false)
	}
	
	func didReadData(notification: NSNotification!) {
		DispatchQueue.main.async { 
			guard let userInfo = notification.userInfo else {
				log(warning: "Recieved readData notification without payload")
				return
			}
			guard let data = userInfo[Server.dataKey] as? String else {
				log(warning: "Recieved readData notification without data")
				return
			}
			self.dataRecievedLabel.stringValue = data
		}
	}
	
	func didWriteData(notification: NSNotification!) {
		DispatchQueue.main.async {
			DispatchQueue.main.async {
				guard let userInfo = notification.userInfo else {
					log(warning: "Recieved writeData notification without payload")
					return
				}
				guard let data = userInfo[Server.dataKey] as? String else {
					log(warning: "Recieved writeData notification without data")
					return
				}
				self.dataSendLabel.stringValue = data
			}
		}
	}
}
