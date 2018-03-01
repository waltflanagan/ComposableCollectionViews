//
//  MappedCollectionViewCellProvider.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import UIKit

/// Class for mapping from a local index path to a global index path to dequeue cells from a wrapped collection view
internal class MappedCollectionViewCellProvider: CollectionViewCellProvider {
    
    fileprivate let _wrappedProvider: CollectionViewCellProvider
    fileprivate let _mapping: ComposedDataSourceMapping
    
    init(provider: CollectionViewCellProvider, dataSourceMapping: ComposedDataSourceMapping) {
        _wrappedProvider = provider
        _mapping = dataSourceMapping
    }
    
    internal func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell {
        return _wrappedProvider.dequeueReusableCell(withReuseIdentifier: identifier, for: _mapping.globalIndexPathForLocalIndexPath(indexPath))
    }
    
    internal func dequeueReusableSupplementaryView(ofKind elementKind: String, withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionReusableView {
        return _wrappedProvider.dequeueReusableSupplementaryView(ofKind: elementKind, withReuseIdentifier: identifier, for:  _mapping.globalIndexPathForLocalIndexPath(indexPath))
    }
    
}
