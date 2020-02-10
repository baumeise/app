//
//  MultipleChoiceCell.swift
//  Amsel
//
//  Created by Anja on 04.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class MultipleChoiceCell: UITableViewCell {

    @IBOutlet var borderView: UIView!
    @IBOutlet var optionLetter: UILabel!
    @IBOutlet var optionText: UILabel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            self.borderView.layer.borderColor = UIColor(named: "Text: Light Petrol")!.cgColor
            self.borderView.layer.borderWidth = 2.0
        } else {
            self.borderView.layer.borderColor = UIColor(named: "Text: Black")!.cgColor
            self.borderView.layer.borderWidth = 1.0
        }
    }
}
