//
//  CodeBlockGapCell.swift
//  Amsel
//
//  Created by Anja on 05.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class CodeBlockGapCell: UICollectionViewCell, UITextFieldDelegate {
    
    @IBOutlet var gapTextField: GapTextField!
    
    var solution: String = "" {
        didSet {
            // Calculate size for current text
            gapTextField.size = (solution as NSString).size(withAttributes: gapTextField.defaultTextAttributes)
            // Update intrinsic content size
            gapTextField.invalidateIntrinsicContentSize()
        }
    }
    
    func passed() -> Bool {
        return gapTextField.text == solution
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        gapTextField.resignFirstResponder()
        return true
    }
}

class GapTextField: UITextField {
    
    var size = CGSize(width: 0, height: 0)
    
    override var intrinsicContentSize: CGSize {
        // Add margin to calculated size
        size.width += 20
        
        return size
    }
}
