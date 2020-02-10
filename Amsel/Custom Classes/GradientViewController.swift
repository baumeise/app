//
//  GradientViewController.swift
//  Amsel
//
//  Created by Anja on 01.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class GradientViewController: UIViewController, CAAnimationDelegate {
    
    //    Animation source:
    //    https://medium.com/flawless-app-stories/animated-gradient-layers-in-swift-bad094496644
    @IBOutlet final var backgroundView: UIView!
    @IBOutlet final var colorView: UIView!
    
    final let gradientLayer = CAGradientLayer()
    final var gradientSet = [[CGColor]]()
    final var currentGradient: Int = 0
    final let animation = CABasicAnimation(keyPath: "colors")
    
//    let gradients: [CGColor]
    let gradients = [UIColor(named: "Gradient: Dark Petrol")!.cgColor,
                     UIColor(named: "Gradient: Light Petrol")!.cgColor]
    
    
    final func createGradient() {
        // Fill cyclic color set
        for (index, currentGradient) in self.gradients.enumerated() {
            var nextGradient = self.gradients[0]
            if index+1 < self.gradients.count {
                nextGradient = self.gradients[index+1]
            }
            gradientSet.append([currentGradient, nextGradient])
        }
        // Set-up gradient layer
        gradientLayer.frame = colorView.bounds
        gradientLayer.colors = gradientSet[currentGradient]
        gradientLayer.startPoint = CGPoint (x: 0, y: 1)
        gradientLayer.endPoint = CGPoint (x: 1, y: 0)
        gradientLayer.drawsAsynchronously = true
        
        colorView.layer.insertSublayer(gradientLayer, at: 0)
    }
        
    final func animateGradient(){
        if currentGradient < gradientSet.count - 1 {
            currentGradient += 1 } else {
            currentGradient = 0
        }
        
        animation.duration = 1.8
        animation.toValue = gradientSet[currentGradient]
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.delegate = self
        animation.autoreverses = false
        animation.isRemovedOnCompletion = false
        animation.repeatCount = 0
        gradientLayer.add(animation, forKey: "colorChange")
        
    }
        
    final func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            gradientLayer.colors = gradientSet[currentGradient]
            animateGradient()
        }
    }
        
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
        createGradient()
        animateGradient()
        
        backgroundView.layer.borderColor = UIColor(named: "Background")!.cgColor
        backgroundView.layer.cornerRadius = 25
        backgroundView.layer.borderWidth = 1.0
        backgroundView.layer.backgroundColor = UIColor(named: "Background")!.cgColor
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
