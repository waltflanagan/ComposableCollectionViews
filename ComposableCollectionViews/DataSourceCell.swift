//
//  DataSourceCell.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import UIKit

protocol DataSourceCell: class {
    static var ReuseIdentifier: String {get}
    static var NibName: String {get}
    static func cellForSizing() -> UICollectionViewCell
}

extension UICollectionView {
    func register(_ cellType: DataSourceCell.Type) {
        let nib = UINib(nibName: cellType.NibName, bundle: nil)
        self.register(nib, forCellWithReuseIdentifier: cellType.ReuseIdentifier)
    }
}

extension DataSourceCell where Self: UICollectionViewCell {
    static func cellForSizing() -> UICollectionViewCell {
        let nib = UINib(nibName: NibName, bundle:nil)
        
        let views = nib.instantiate(withOwner: self, options: nil)
        guard let cell = views.first as? Self else { preconditionFailure("Wrong cell returned")}
        //This sucks.
        // estimatedItemSize is completely broken and crashing on iOS 9... so we do it the old fashioned way.
        
        return cell
    }
}

