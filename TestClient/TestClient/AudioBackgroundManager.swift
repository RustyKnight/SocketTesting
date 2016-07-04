//
//  AudioBackgroundManager.swift
//  TestClient
//
//  Created by Shane Whitehead on 4/07/2016.
//  Copyright © 2016 KaiZen. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

typealias AudioBackgroundTask = () -> Void

class AudioBackgroundManager {
    static let instance = AudioBackgroundManager()

    internal var timeInterval: TimeInterval?
    internal var target: AudioBackgroundTask?

    internal let queue: DispatchQueue = DispatchQueue(label: "AudioBackground")

    internal var bgTask: UIBackgroundTaskIdentifier?

    internal var player: AVAudioPlayer?
    internal var timer: Timer?

    init() {
    }

    func start(with: TimeInterval, target: AudioBackgroundTask) {
        timeInterval = with
        self.target = target
        initBackgroundTask()
    }

    func stop() {
        stopAudio()
    }

    internal func initBackgroundTask() {
        guard let _ = timeInterval, let _ = target else {
            return
        }
        queue.async { 
            if self.running {
                self.stopAudio()
            }

            while self.running {
                Thread.sleep(forTimeInterval: 10.0)
            }

            self.playAudio()
        }
    }

    func stopAudio() {
        NotificationCenter.default().removeObserver(self, name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
        if let timer = timer {
            timer.invalidate()
        }
        timer = nil
        if let player = player {
            player.stop()
        }
        player = nil
        if let bgTask = bgTask {
            UIApplication.shared().endBackgroundTask(bgTask)
        }
        bgTask = nil
    }

    func playAudio() {
        guard let timeInterval = timeInterval, let _ = target else {
            return
        }
        let app = UIApplication.shared()
        NotificationCenter.default().addObserver(self,
                                                 selector: #selector(AudioBackgroundManager.audioInterrupted),
                                                 name: NSNotification.Name.AVAudioSessionInterruption,
                                                 object: nil)

        bgTask = app.beginBackgroundTask(expirationHandler: {
            if let bgTask = self.bgTask {
                app.endBackgroundTask(bgTask)
            }
            self.bgTask = nil
            if let timer = self.timer {
                timer.invalidate()
            }
            self.timer = nil
            if let player = self.player {
                player.stop()
            }
            self.player = nil
            log(warning: "Background task expired")
        })

        DispatchQueue.main.async {
            let bytes: [UInt8] = [0x52, 0x49, 0x46, 0x46, 0x26, 0x0, 0x0, 0x0, 0x57, 0x41, 0x56, 0x45, 0x66, 0x6d, 0x74, 0x20,
                         0x10, 0x0, 0x0, 0x0, 0x1, 0x0, 0x1, 0x0, 0x44, 0xac, 0x0, 0x0, 0x88, 0x58, 0x1, 0x0, 0x2, 0x0,
                         0x10, 0x0, 0x64, 0x61, 0x74, 0x61, 0x2, 0x0, 0x0, 0x0, 0xfc, 0xff]
            let data = Data(bytes: bytes)

            guard let docsDir = FileManager.default().urlsForDirectory(FileManager.SearchPathDirectory.documentDirectory,
                                                                       inDomains: FileManager.SearchPathDomainMask.userDomainMask).first else {
                                                                return
            }

            do {
                let filePath = try docsDir.appendingPathComponent("background.wav")
                try data.write(to: filePath, options: .dataWritingAtomic)

                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
                try AVAudioSession.sharedInstance().setActive(true)

                self.player = try AVAudioPlayer(contentsOf: filePath)
                self.player?.volume = 0.01
                self.player?.numberOfLoops = -1
                self.player?.prepareToPlay()
                self.player?.play()

                self.timer = Timer.scheduledTimer(timeInterval: timeInterval,
                                             target: self,
                                             selector: #selector(AudioBackgroundManager.tick),
                                             userInfo: nil,
                                             repeats: true)
            } catch let error {
                log(error: "\(error)")
            }

        }
    }

    @objc func tick() {
        guard let target = target else {
            return
        }
        target()
    }

    @objc func audioInterrupted(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            log(warning: "Interrupted without any info")
            return
        }
        guard let type = userInfo[AVAudioSessionInterruptionTypeKey] as? Int else {
            log(warning: "Bad interrupt type")
            return
        }
        if type == 1 {
            initBackgroundTask()
        }
    }

    var running: Bool {
        return bgTask != nil
    }
}
