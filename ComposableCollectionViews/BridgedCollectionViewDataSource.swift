//
//  CollectionViewDataSourceBridge.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import UIKit

extension UICollectionView : CollectionViewCellProvider {}

///Class for bridging from a CollectionViewDataSource to an actual UICollectionViewDataSource
class BridgedCollectionViewDataSource: NSObject, UICollectionViewDataSource {

    let dataSource: CollectionViewDataSource

    init(dataSource: CollectionViewDataSource) {
        self.dataSource = dataSource
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.numberOfSections()
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.numberOfItemsInSection(section)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return dataSource.cellProvider(collectionView, cellForItemAtIndexPath: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        return dataSource.cellProvider(collectionView, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath)
    }
}
