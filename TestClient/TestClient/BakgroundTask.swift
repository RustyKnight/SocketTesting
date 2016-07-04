//
//  BakgroundTask.swift
//  TestClient
//
//  Created by Shane Whitehead on 4/07/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import UIKit

class BackgroundTaskManager {
    static let instance = BackgroundTaskManager()

    var task: BackgroundTask?
    var timer: Timer?
    var count: Int = 0

    func start() {
        guard timer == nil else {
            return
        }
        task = startTask()
        timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(BackgroundTaskManager.tick), userInfo: nil, repeats: true)
    }

    func stop() {
        guard let timer = timer else {
            return
        }
        timer.invalidate()
        self.timer = nil

        guard let task = task else {
            return
        }
        stopTask(task)
    }

    internal func startTask() -> BackgroundTask {
        let task = BackgroundTask(with: count)
        task.start()
        count += 1
        return task
    }

    internal func stopTask(_ task: BackgroundTask) {
        task.stop()
        self.task = nil
    }

    @objc func tick() {
        let old = task
        self.task = self.startTask()
        if let old = old {
            DispatchQueue.main.async {
                log(info: "Restart task")
                self.stopTask(old)
            }
        }
    }
}

class BackgroundTask {

    var identifer: UIBackgroundTaskIdentifier?
    let number: Int

    init(with number: Int) {
        self.number = number
    }

    func start() {
        identifer = UIApplication.shared().beginBackgroundTask {
            NotificationService.instance.showNotification(withTitle: "Background", andBody: "Expired")
            self.stop()
        }
        log(info: "\(number): Started background task with \(identifer)")
    }

    func stop() {
        guard let identifer = identifer else {
            return
        }
        log(info: "\(number): Stop task with identifer = \(identifer)")
        UIApplication.shared().endBackgroundTask(identifer)
    }

}
