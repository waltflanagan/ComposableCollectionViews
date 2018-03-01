//
//  MultiplexedCollectionViewDatasource.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import UIKit


class MultiplexedCollectionViewDataSource: MultiplexedDataSource, CollectionViewDataSource {

    fileprivate var _collectionViewDatasources: [CollectionViewDataSource]

    fileprivate var _activeCollectionViewDataSource: CollectionViewDataSource {
        guard let dataSource = activeDataSource as? CollectionViewDataSource else {preconditionFailure("Needs to be a CollectionViewDataSource") }
        return dataSource
    }

    init(datasources: [CollectionViewDataSource]) {
        _collectionViewDatasources = datasources
        let baseClassDatasources = datasources.map { $0 as DataSource }
        super.init(datasources: baseClassDatasources)
    }

    func cellProvider(_ cellProvider: CollectionViewCellProvider, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        return _activeCollectionViewDataSource.cellProvider(cellProvider, cellForItemAtIndexPath: indexPath)
    }

    func cellProvider(_ cellProvider: CollectionViewCellProvider, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: IndexPath) -> UICollectionReusableView {
        return _activeCollectionViewDataSource.cellProvider(cellProvider, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath)
    }
    
    func updateCell(_ cell: UICollectionViewCell, withItem item: Any, atIndexPath indexPath: IndexPath) {
        _activeCollectionViewDataSource.updateCell(cell, withItem: item, atIndexPath: indexPath)
    }

    func registerReusableViewsWithCollectionView(_ collectionView: UICollectionView) {
        for datasource in _collectionViewDatasources {
            datasource.registerReusableViewsWithCollectionView(collectionView)
        }
    }

}
