//
//  ViewController.swift
//  TestClient
//
//  Created by Shane Whitehead on 30/06/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

	@IBOutlet weak var connectSwitch: UISwitch!
	@IBOutlet weak var connectActivty: UIActivityIndicatorView!
	
	@IBOutlet weak var serverField: UITextField!
	@IBOutlet weak var portField: UITextField!
	
	@IBOutlet weak var notConnectedLabel: UILabel!
	@IBOutlet weak var connectedLabel: UILabel!
	
	@IBOutlet weak var sendDataButton: UIButton!
	
	@IBOutlet weak var timeIntervalLabel: UILabel!
	@IBOutlet weak var timeIntervalSlider: UISlider!
	@IBOutlet weak var timeIntervalSegment: UISegmentedControl!
	
	@IBOutlet weak var autoTransmitSwitch: UISwitch!
	@IBOutlet weak var autoTransmitLabel: UILabel!
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		NotificationCenter.default().addObserver(self,
		                                         selector: #selector(ViewController.didConnect),
		                                         name: ServerService.ServerConnectedNotification,
		                                         object: nil)
		NotificationCenter.default().addObserver(self,
		                                         selector: #selector(ViewController.didDisconnect),
		                                         name: ServerService.ServerDisconnectedNotification,
		                                         object: nil)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		NotificationCenter.default().removeObserver(self,
		                                            name: ServerService.ServerConnectedNotification,
		                                            object: nil)
		NotificationCenter.default().removeObserver(self,
		                                            name: ServerService.ServerDisconnectedNotification,
		                                            object: nil)
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	@IBAction func timeIntervalChanged(_ sender: AnyObject) {
		updateTimeIntervalLabel()
	}

	@IBAction func connectChanged(_ sender: AnyObject) {
		switch connectSwitch.isOn {
		case true:
			transitionConnectionState(connecting: true)
			guard let host = serverField.text,
				let portValue = portField.text,
				let port = UInt16(portValue) else {
				return
			}
			doInBackground({ 
				try ServerService.default.connect(to: host, port: port)
				}, complition: { (error) in
					if let error = error {
						self.showAlert(withTitle: "Error", message: "\(error)")
					}
			})
		case false:
			ServerService.default.disconnect()
		}
	}
	
	func transitionConnectionState(connecting: Bool) {
		log(info: "connecting \(connecting)")
		connectSwitch.transition(hidden: connecting)
		connectActivty.transition(hidden: !connecting)
	}
	
	@IBAction func sendDataManually(_ sender: AnyObject) {
		ServerService.default.sendData()
	}
}

extension ViewController {
	
	func did(connect: Bool) {
		log(info: "connect = \(connect)")
		connectedLabel.transition(hidden: !connect)
		notConnectedLabel.transition(hidden: connect)
		
		if connectSwitch.isOn != connect {
			connectSwitch.isOn = connect
		}
		transitionConnectionState(connecting: false)
		
		sendDataButton.isEnabled = connect
		autoTransmitLabel.isEnabled = connect
		autoTransmitSwitch.isEnabled = connect
	}
	
	func didConnect(_ notification: Notification!) {
		did(connect: true)
	}
	
	func didDisconnect(_ notification: Notification!) {
		did(connect: false)
	}
}

extension ViewController {
	var timeInterval: TimeInterval {
		let timeRange = (9.0 * 60.0) + 30.0
		let interval = Double(timeIntervalSlider.value) * timeRange
		return 30.0 + interval
	}
	
	func updateTimeIntervalLabel() {
		let time = timeInterval
		let formatter = DateComponentsFormatter()
		
		formatter.unitsStyle = .full
		formatter.allowedUnits = [Calendar.Unit.second, Calendar.Unit.minute]
		timeIntervalLabel.text = formatter.string(from: time) ?? "?"
	}
}

extension UIView {
	
	func transition(hidden: Bool, animated: Bool = true, duration: TimeInterval = 0.25) {
		UIView.transition(with: self,
		                  duration: duration,
		                  options: .transitionCrossDissolve,
		                  animations: {
			self.isHidden = hidden
			}, completion: nil)
	}
	
}

extension UIViewController {
	
	func showAlert(withTitle title: String, message: String) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
		self.present(alert, animated: true, completion: nil)
	}
	
}

func doInBackground(_ callBack: () throws -> Void, complition: (ErrorProtocol?) -> Void) {
	DispatchQueue.global().sync(execute: {
		do {
			try callBack()
			DispatchQueue.main.async(execute: { 
				complition(nil)
			})
		} catch let error {
			DispatchQueue.main.async(execute: {
				complition(error)
			})
		}
	})

}
