//
//  LiteratureViewController.swift
//  Amsel
//
//  Created by Anja on 30.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class LiteratureViewController: UIViewController {
    
    @IBAction func mimo(_ sender: Any) {
        guard let url = URL(string: "https://getmimo.com") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBAction func cheat(_ sender: Any) {
        guard let url = URL(string: "https://sinxloud.com/de/python-cheat-sheet-beginner-advanced/") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBAction func pythonZero(_ sender: Any) {
        guard let url = URL(string: "https://medium.com/the-renaissance-developer/learning-python-from-zero-to-hero-8ceed48486d5") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBAction func amsel(_ sender: Any) {
        guard let url = URL(string: "https://baumeise.github.io/amsel/getting-started/#prerequisites") else { return }
        UIApplication.shared.open(url)
    }
}
