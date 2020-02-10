//
//  MultipleChoiceTable.swift
//  Amsel
//
//  Created by Anja on 01.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class MultipleChoiceTable: UITableView {

    override var contentSize:CGSize {
        didSet {
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        self.layoutIfNeeded()
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }

}
