//
//  CodeBlockCollectionView.swift
//  Amsel
//
//  Created by Anja on 05.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class CodeBlockCollectionView: UICollectionView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !__CGSizeEqualToSize(bounds.size, self.intrinsicContentSize) {
            self.invalidateIntrinsicContentSize()
        }
    }

    override var intrinsicContentSize: CGSize {
        return contentSize
    }
}
