//
//  CollectionViewDataSource.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import UIKit

protocol CollectionViewCellProvider {
    func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell
    func dequeueReusableSupplementaryView(ofKind elementKind: String, withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionReusableView
}

protocol CollectionViewDataSource : DataSource {
    func cellProvider(_ cellProvider: CollectionViewCellProvider, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell
    func cellProvider(_ cellProvider: CollectionViewCellProvider, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: IndexPath) -> UICollectionReusableView
    func registerReusableViewsWithCollectionView(_ collectionView: UICollectionView)
    func updateCell(_ cell: UICollectionViewCell, withItem item: Any, atIndexPath: IndexPath)
}
