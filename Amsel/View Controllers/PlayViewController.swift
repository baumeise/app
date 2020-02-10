//
//  PlayViewController.swift
//  Amsel
//
//  Created by Anja on 01.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class PlayViewController: GradientViewController {
    
    @IBOutlet var connectionLabel: UILabel!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var driveSlider: UISlider!
    @IBOutlet var steerSlider: UISlider!
    
    private var driveTimer = Timer()
    private var steerTimer = Timer()
    private var connectionTimer = Timer()
    private var distanceTimer = Timer()
    
    private let controlUpdateRate = 0.1
    private let distanceUpdateRate = 1.0
    private let connectionUpdateRate = 0.3
    private let sliderDeadRange: Float = 8
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        var text=""
        switch UIDevice.current.orientation{
        case .portrait:
            text="Portrait"
        case .portraitUpsideDown:
            text="PortraitUpsideDown"
        case .landscapeLeft:
            text="LandscapeLeft"
        case .landscapeRight:
            text="LandscapeRight"
        default:
            text="Another"
        }
        print("You have moved: \(text)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        driveSlider.setThumbImage(UIImage(named: "slider.thumb.arrows"), for: .normal)
        driveSlider.setMinimumTrackImage(UIImage(named: "slider.track"), for: .normal)
        driveSlider.setMaximumTrackImage(UIImage(named: "slider.track"), for: .normal)
        steerSlider.setThumbImage(UIImage(named: "slider.thumb.arrows"), for: .normal)
        steerSlider.setMinimumTrackImage(UIImage(named: "slider.track"), for: .normal)
        steerSlider.setMaximumTrackImage(UIImage(named: "slider.track"), for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        connectionTimer = Timer.scheduledTimer(timeInterval: connectionUpdateRate, target: self, selector: #selector(self.checkConnection), userInfo: nil, repeats: true)
        distanceTimer = Timer.scheduledTimer(timeInterval: distanceUpdateRate, target: self, selector: #selector(self.measureDistance), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        connectionTimer.invalidate()
        distanceTimer.invalidate()
        Amsel.shared.stop()
    }
    
    @objc func checkConnection() {
        if Amsel.shared.status == .AMSEL_UDP_ONLY || Amsel.shared.status == .AMSEL_TCP_UDP {
            connectionLabel.text = "Connection: available"
        } else {
            connectionLabel.text = "Connection: not available"
        }
    }
    
    @objc func measureDistance() {
        Amsel.shared.distance_tcp(completion: { distance in
            DispatchQueue.main.async {
                self.distanceLabel.text = "Distance: \(distance) cm"
            }
        })
    }
    
    @IBAction func startDriving(_ sender: UISlider) {
        driveTimer = Timer.scheduledTimer(timeInterval: controlUpdateRate, target: self, selector: #selector(self.drive), userInfo: nil, repeats: true)
    }
    
    @IBAction func stopDriving(_ sender: UISlider) {
        driveTimer.invalidate()
        Amsel.shared.stopDriving()
        driveSlider.value = 0
    }
    
    @objc func drive() {
        if driveSlider.value > sliderDeadRange {
            Amsel.shared.forward(speed: abs(driveSlider.value))
        } else if driveSlider.value < -sliderDeadRange {
            Amsel.shared.reverse(speed: abs(driveSlider.value))
        } else {
            Amsel.shared.stopDriving()
        }
    }
    
    @IBAction func startSteering(_ sender: UISlider) {
        steerTimer = Timer.scheduledTimer(timeInterval: controlUpdateRate, target: self, selector: #selector(self.steer), userInfo: nil, repeats: true)
    }
    
    @IBAction func stopSteering(_ sender: UISlider) {
        steerTimer.invalidate()
        Amsel.shared.stopSteering()
        steerSlider.value = 0
    }
    
    @objc func steer() {
        let steerFactor = Float(0.5) // to make steering more sensitive
        
        if steerSlider.value > sliderDeadRange {
            Amsel.shared.right(speed: abs(steerSlider.value * steerFactor))
        } else if steerSlider.value < -sliderDeadRange {
            Amsel.shared.left(speed: abs(steerSlider.value * steerFactor))
        } else {
            Amsel.shared.stopSteering()
        }
    }
    
}

