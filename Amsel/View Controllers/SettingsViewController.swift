//
//  SettingsViewController.swift
//  Amsel
//
//  Created by Anja on 01.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    @IBAction func resetUserAction(_ sender: Any) {
        resetUser()
    }

}
