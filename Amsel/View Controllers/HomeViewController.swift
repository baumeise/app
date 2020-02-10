//
//  HomeViewController.swift
//  Amsel
//
//  Created by Anja on 17.11.19.
//  Copyright © 2019 Anja. All rights reserved.
//

import UIKit

class HomeViewController: GradientViewController {
    
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var connectionView: UIView!
    @IBOutlet var connectionButton: UIButton!
    
    @IBAction func connectionButtonAction(_ sender: Any) {
        Amsel.shared.connect(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let buttonGradient = CAGradientLayer()
        
        buttonGradient.colors = [UIColor(named: "Gradient: Dark Petrol")!.cgColor, UIColor(named: "Gradient: Light Petrol")!.cgColor]
        buttonGradient.startPoint = CGPoint (x: 0.0, y: 1.0)
        buttonGradient.endPoint = CGPoint (x: 1.0, y:0.0)
        connectionButton.layer.borderColor = UIColor(named: "Background")!.cgColor
        connectionButton.layer.borderWidth = 1.0
        connectionButton.layer.cornerRadius = 20
        buttonGradient.frame = connectionButton.bounds
        connectionButton.clipsToBounds = true
        connectionButton.layer.insertSublayer(buttonGradient, at: 0)
    }
}
