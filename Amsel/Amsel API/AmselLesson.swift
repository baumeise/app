//
//  AmselLesson.swift
//  Amsel
//
//  Created by Martin Rabel on 26.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import Foundation

class AmselLesson {
    static let shared = AmselLesson()
    
    private var activeLesson = Lesson.none
    private var lessonData = [String: String]()
    
    private var driveTimer = Timer()
    private var steerTimer = Timer()
    private var connectionTimer = Timer()
    private var distanceTimer = Timer()
    private var printTimer = Timer()
    private var stopTimer = Timer()
    
    private let controlUpdateRate = 0.33
    private let connectionUpdateRate = 1.3
    private let printUpdateRate = 1.0
    private let distanceUpdateRate = 0.3
    
    enum Lesson {
        case none
        case driveTillBarrier
        case print
        case driveCircle
        case driveStraight
    }
    enum Direction: String {
        case left = "-2"
        case right = "-1"
        case reverse = "1"
        case forward = "2"
    }
    
    private init() {}
    
    public func driveTillBarrier() {
        if activeLesson == .none {
            activeLesson = .driveTillBarrier
            connectionTimer = Timer.scheduledTimer(timeInterval: connectionUpdateRate, target: self, selector: #selector(self.checkConnection), userInfo: nil, repeats: true)
            
            distanceTimer = Timer.scheduledTimer(timeInterval: distanceUpdateRate, target: self, selector: #selector(self.measureDistance), userInfo: nil, repeats: true)
            driveTimer = Timer.scheduledTimer(timeInterval: controlUpdateRate, target: self, selector: #selector(self.drive), userInfo: nil, repeats: true)
        }
    }
    public func amselPrint(_ text: String) {
        if activeLesson == .none {
            print(text)
            activeLesson = .print
            connectionTimer = Timer.scheduledTimer(timeInterval: connectionUpdateRate, target: self, selector: #selector(self.checkConnection), userInfo: nil, repeats: true)
            
            printTimer = Timer.scheduledTimer(timeInterval: printUpdateRate, target: self, selector: #selector(self.printText), userInfo: nil, repeats: true)
            lessonData["text"] = text
        } else if activeLesson == .print {
            lessonData["text"] = text
        }
    }
    public func driveCircle(seconds: Int, direction: Direction = .left) {
        if activeLesson == .none {
            activeLesson = .driveCircle
            connectionTimer = Timer.scheduledTimer(timeInterval: connectionUpdateRate, target: self, selector: #selector(self.checkConnection), userInfo: nil, repeats: true)
            
            steerTimer = Timer.scheduledTimer(timeInterval: controlUpdateRate, target: self, selector: #selector(self.steer), userInfo: nil, repeats: true)
            stopTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.stop), userInfo: nil, repeats: true)
            lessonData["direction"] = direction.rawValue
        } else if activeLesson == .driveCircle {
            lessonData["direction"] = direction.rawValue
            stopTimer.invalidate()
            stopTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.stop), userInfo: nil, repeats: true)
        }
    }
    public func driveStraight(seconds: Int, direction: Direction = .forward) {
        if activeLesson == .none {
            activeLesson = .driveStraight
            connectionTimer = Timer.scheduledTimer(timeInterval: connectionUpdateRate, target: self, selector: #selector(self.checkConnection), userInfo: nil, repeats: true)
            
            driveTimer = Timer.scheduledTimer(timeInterval: controlUpdateRate, target: self, selector: #selector(self.drive), userInfo: nil, repeats: true)
            stopTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.stop), userInfo: nil, repeats: true)
            lessonData["direction"] = direction.rawValue
        } else if activeLesson == .driveStraight {
            lessonData["direction"] = direction.rawValue
            stopTimer.invalidate()
            stopTimer = Timer.scheduledTimer(timeInterval: TimeInterval(seconds), target: self, selector: #selector(self.stop), userInfo: nil, repeats: true)
        }
    }
    public func stopAll() {
        self.distanceTimer.invalidate()
        self.driveTimer.invalidate()
        self.steerTimer.invalidate()
        self.printTimer.invalidate()
        self.connectionTimer.invalidate()
        self.stopTimer.invalidate()
        self.lessonData.removeAll()
        self.activeLesson = .none
        DispatchQueue.global(qos: .background).async {
            Amsel.shared.stop()
            Amsel.shared.safe_reset_tcp()
        }
    }
    
    @objc private func checkConnection() {
        // Stop lessons, if no TCP connection is available anymore
        Amsel.shared.checkConnection()
        if Amsel.shared.status != .AMSEL_TCP_ONLY && Amsel.shared.status != .AMSEL_TCP_UDP {
            stopAll()
        }
    }
    
    @objc private func printText() {
        switch activeLesson {
        case .print:
            if let text = lessonData["text"] {
                Amsel.shared.print_tcp(text)
            }
        default:
            Amsel.shared.print_tcp("")
            lessonData.removeValue(forKey: "text")
            printTimer.invalidate()
        }
    }
    
    @objc private func measureDistance() {
        switch activeLesson {
        case .driveTillBarrier:
            Amsel.shared.distance_tcp(completion: { distance in
                DispatchQueue.main.async {
                    self.lessonData["distance"] = distance
                }
            })
        default:
            lessonData.removeValue(forKey: "distance")
            distanceTimer.invalidate()
        }
    }
    
    @objc private func drive() {
        let driveSpeedDefault = Float(50)
        switch activeLesson {
        case .driveTillBarrier:
            if let distance = lessonData["distance"], (Int(distance) ?? -1) > 30 {
                Amsel.shared.forward_tcp(speed: driveSpeedDefault)
            } else if let distance = lessonData["distance"], (Int(distance) ?? -1) > 0 {
                stopAll()
            }
        case .driveStraight:
            if let direction = lessonData["direction"], direction == Direction.forward.rawValue {
                Amsel.shared.forward_tcp(speed: driveSpeedDefault)
            } else if let direction = lessonData["direction"], direction == Direction.reverse.rawValue { // larger than zero -> right
                Amsel.shared.reverse_tcp(speed: driveSpeedDefault)
            } else {
                stopAll()
            }
        default:
            Amsel.shared.stopDriving_tcp()
            driveTimer.invalidate()
        }
    }
    
    @objc private func steer() {
        let steerSpeedDefault = Float(50)
        switch activeLesson {
        case .driveCircle:
            if let direction = lessonData["direction"], direction == Direction.left.rawValue {
                Amsel.shared.left_tcp(speed: steerSpeedDefault)
            } else if let direction = lessonData["direction"], direction == Direction.right.rawValue { // larger than zero -> right
                Amsel.shared.right_tcp(speed: steerSpeedDefault)
            } else {
                stopAll()
            }
        default:
            Amsel.shared.stopSteering_tcp()
            steerTimer.invalidate()
        }
    }
    
    @objc private func stop() {
        stopAll()
    }
}
