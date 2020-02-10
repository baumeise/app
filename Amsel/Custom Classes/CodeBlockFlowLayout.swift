//
//  CodeBlockFlowLayout.swift
//  Amsel
//
//  Created by Anja on 05.01.20.
//  Copyright © 2020 Anja. All rights reserved.
//

import UIKit

class CodeBlockFlowLayout: UICollectionViewFlowLayout {
    
    var outputSections: [Int] = []

    required init(minimumInteritemSpacing: CGFloat = 0, minimumLineSpacing: CGFloat = 0, sectionInset: UIEdgeInsets = .zero) {
        super.init()

        estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        self.minimumInteritemSpacing = minimumInteritemSpacing
        self.minimumLineSpacing = minimumLineSpacing
        self.sectionInset = sectionInset
        sectionInsetReference = .fromSafeArea
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepare() {
        super.prepare()
        
        register(SCSBCollectionReusableView.self, forDecorationViewOfKind: "sectionBackground")
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        // ---- Align all cells to the left
        let layoutAttributes = super.layoutAttributesForElements(in: rect)!.map { $0.copy() as! UICollectionViewLayoutAttributes }
        guard scrollDirection == .vertical else { return layoutAttributes }

        // Filter attributes to compute only cell attributes
        let cellAttributes = layoutAttributes.filter({ $0.representedElementCategory == .cell })

        // Group cell attributes by row (cells with same vertical center) and loop on those groups
        for (_, attributes) in Dictionary(grouping: cellAttributes, by: { ($0.center.y / 10).rounded(.up) * 10 }) {
            // Set the initial left inset
            var leftInset = sectionInset.left

            // Loop on cells to adjust each cell's origin and prepare leftInset for the next cell
            for attribute in attributes {
                attribute.frame.origin.x = leftInset
                leftInset = attribute.frame.maxX + minimumInteritemSpacing
            }
        }
        
        // ---- Set section color
        var allAttributes = [UICollectionViewLayoutAttributes]()
        
        for attr in layoutAttributes {
            // Look for the first item in a row
            if (attr.representedElementCategory == UICollectionView.ElementCategory.cell && attr.frame.origin.x == self.sectionInset.left) {

                // Create decoration attributes
                let decorationAttributes = SCSBCollectionViewLayoutAttributes(forDecorationViewOfKind: "sectionBackground", with: attr.indexPath)
                // Set the color(s)
                if outputSections.contains(attr.indexPath.section) {
                    decorationAttributes.color = UIColor(named: "Gradient: Lighter Petrol")!
                } else {
                    decorationAttributes.color = UIColor.clear
                }

                // Make the decoration view span the entire row
                let tmpWidth = self.collectionView!.contentSize.width
                let tmpHeight = attr.frame.size.height + self.minimumLineSpacing + self.sectionInset.top / 2 + self.sectionInset.bottom / 2
                decorationAttributes.frame = CGRect(x: 0, y: attr.frame.origin.y - self.sectionInset.top, width: tmpWidth, height: tmpHeight)

                // Set the zIndex to be behind the item
                decorationAttributes.zIndex = attr.zIndex - 1

                // Add the attribute to the list
                allAttributes.append(decorationAttributes)
            }
        }
        // Combine the items and decorations arrays
        allAttributes.append(contentsOf: layoutAttributes)

        return allAttributes
    }
    
    class SCSBCollectionViewLayoutAttributes : UICollectionViewLayoutAttributes {
        var color: UIColor = .white
        
        override func copy(with zone: NSZone? = nil) -> Any {
            let newAttributes: SCSBCollectionViewLayoutAttributes = super.copy(with: zone) as! SCSBCollectionViewLayoutAttributes
            newAttributes.color = self.color.copy(with: zone) as! UIColor
            return newAttributes
        }
    }

    class SCSBCollectionReusableView : UICollectionReusableView {
        
        override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
            super.apply(layoutAttributes)
            
            let scLayoutAttributes = layoutAttributes as! SCSBCollectionViewLayoutAttributes
            self.backgroundColor = scLayoutAttributes.color
        }
    }
}
