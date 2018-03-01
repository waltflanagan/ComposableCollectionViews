//
//  EmptyableDataSource.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import UIKit


struct EmptyDataSourceItem {}

@objc public enum LoadingState: Int {
    case unloaded
    case loading
    case loaded
    case error
}

public protocol Loadable {
    var loadingState: LoadingState { get }
}


class LoadableCollectionViewDataSource<EmptyCellType:DataSourceCell, LoadingCellType:DataSourceCell>: LoadableDataSource, CollectionViewDataSource {

    fileprivate var _dataSource: CollectionViewDataSource

    init(datasource: CollectionViewDataSource) {
        _dataSource = datasource
        super.init(datasource: datasource as DataSource)
    }
    
    func cellProvider(_ cellProvider: CollectionViewCellProvider, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        
        guard _wrappedDatasourceIsLoaded() else {
            return cellProvider.dequeueReusableCell(withReuseIdentifier: LoadingCellType.ReuseIdentifier, for: indexPath)
        }
        
        guard _wrappedDatasourceHasData() else {
            return cellProvider.dequeueReusableCell(withReuseIdentifier: EmptyCellType.ReuseIdentifier, for: indexPath)
        }
        
        return _dataSource.cellProvider(cellProvider, cellForItemAtIndexPath: indexPath)
    }
    
    func cellProvider(_ cellProvider: CollectionViewCellProvider, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: IndexPath) -> UICollectionReusableView {
        return _dataSource.cellProvider(cellProvider, viewForSupplementaryElementOfKind: kind, atIndexPath: indexPath)
    }
    
    
    func updateCell(_ cell: UICollectionViewCell, withItem item: Any, atIndexPath indexPath: IndexPath) {
        guard _wrappedDatasourceHasData() else { return }
        _dataSource.updateCell(cell, withItem: item, atIndexPath: indexPath)
    }
    
    func registerReusableViewsWithCollectionView(_ collectionView: UICollectionView) {
        _dataSource.registerReusableViewsWithCollectionView(collectionView)
        
        let emptyNib = UINib(nibName:EmptyCellType.NibName, bundle:nil)
        collectionView.register(emptyNib, forCellWithReuseIdentifier: EmptyCellType.ReuseIdentifier)
        
        let loadingNib = UINib(nibName:LoadingCellType.NibName, bundle:nil)
        collectionView.register(loadingNib, forCellWithReuseIdentifier: LoadingCellType.ReuseIdentifier)
    }
    
}


class LoadableDataSource: DataSource {
    
    weak var delegate: DataSourceDelegate? = nil
    
    let emptyCellIndexPath = IndexPath(item: 0, section: 0)
    
    fileprivate let _wrappedDataSource: DataSource
    
    init(datasource: DataSource) {
        _wrappedDataSource = datasource
    
        datasource.delegate = self
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> Any {
        guard _wrappedDatasourceIsLoaded() && _wrappedDatasourceHasData() else {
            return EmptyDataSourceItem()
        }
        
        return _wrappedDataSource.itemAtIndexPath(indexPath)
    }
    
    func numberOfItemsInSection(_ section: Int) -> Int {
        guard _wrappedDatasourceIsLoaded() else {
            return 1
        }
        
        guard _wrappedDatasourceHasData() else {
            return 1
        }
        
        return _wrappedDataSource.numberOfItemsInSection(section)
    }
    
    func numberOfSections() -> Int {
        guard _wrappedDatasourceIsLoaded() else { return 1 }

        guard _wrappedDatasourceHasData() else { return 1 }
        
        return _wrappedDataSource.numberOfSections()
    }
    
    func numberOfItemsInAllSections() -> Int {
        guard _wrappedDatasourceIsLoaded() else {
            return 1
        }

        guard _wrappedDatasourceHasData() else {
            return 1
        }

        return _wrappedDataSource.numberOfItemsInAllSections()
    }
    
    fileprivate func _wrappedDatasourceHasData() -> Bool {
        return _wrappedDataSource.numberOfItemsInAllSections() > 0
    }
    
    fileprivate func _wrappedDatasourceIsLoaded() -> Bool {
        guard let loadableDataSource = _wrappedDataSource as? Loadable else { return true }
        return loadableDataSource.loadingState == .loaded
    }
    
}


extension LoadableDataSource : RefreshableDataSource {
    func refreshContent(_ completion: (() -> Void)?) {
        guard let refreshable = _wrappedDataSource as? RefreshableDataSource else { return }
        
        refreshable.refreshContent(completion)
    }
}

extension LoadableDataSource: DataSourceDelegate {

    func dataSource(_ dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [IndexPath]) {
      
        guard _wrappedDatasourceIsLoaded() else {
            return
        }
        
        if let index = indexPaths.index(of: emptyCellIndexPath) {
            notifyItemsRemovedAtIndexPaths([emptyCellIndexPath])
            notifyItemsInsertedAtIndexPaths([emptyCellIndexPath])
            
            var newIndexPaths = indexPaths
            newIndexPaths.remove(at: index)

            notifyItemsInsertedAtIndexPaths(newIndexPaths)
            
        } else {
            notifyItemsInsertedAtIndexPaths(indexPaths)
        }
    }
    
    func dataSource(_ dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [IndexPath]) {
        
        guard _wrappedDatasourceIsLoaded() else { return }
        
        notifyItemsRemovedAtIndexPaths(indexPaths)
        
        if indexPaths.contains(emptyCellIndexPath) {
            notifyItemsInsertedAtIndexPaths([emptyCellIndexPath])
        }
        
    }
    
    func dataSource(_ dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard _wrappedDatasourceIsLoaded() else { return }
        notifyItemsRefreshedAtIndexPaths(indexPaths)
    }
    
    func dataSource(_ dataSource: DataSource, didRefreshIndexPathsWithItems indexPaths: [IndexPath : Any]) {
        guard _wrappedDatasourceIsLoaded() else { return }
        notifyItemsAndIndexPathsRefreshed(indexPaths)
    }
    
    func dataSource(_ dataSource: DataSource, didMoveItemAtIndexPath fromIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath) {
        guard _wrappedDatasourceIsLoaded() else { return }
        notifyItemMovedFromIndexPath(fromIndexPath, toIndexPath: newIndexPath)
    }
    
    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
        
        guard _wrappedDatasourceIsLoaded() else { return }
        
        let emptySection = emptyCellIndexPath.section

        if sections.contains(emptySection) {

            var mutableSections = sections
            mutableSections.remove(emptySection)
            
            notifySectionsRefreshed(IndexSet(integer: emptyCellIndexPath.section))
            
            if mutableSections.count > 0 {
                notifySectionsInserted(mutableSections)
            }

        } else {
            notifySectionsInserted(sections)
        }

    }
    
    func dataSource(_ dataSource: DataSource, didRemoveSections sections: IndexSet) {
        
        guard _wrappedDatasourceIsLoaded() else { return }
        
        notifySectionsRemoved(sections)
        
        let emptySection = emptyCellIndexPath.section
        
        if sections.contains(emptySection) {
            notifySectionsInserted(IndexSet(integer: emptyCellIndexPath.section))
        }
    }
    
    func dataSource(_ dataSource: DataSource, didRefreshSections sections: IndexSet) {
        guard _wrappedDatasourceIsLoaded() else { return }
        notifySectionsRefreshed(sections)
    }
    
    func dataSource(_ dataSource: DataSource, didMoveSection section: Section, toSection newSection: Section) {
        guard _wrappedDatasourceIsLoaded() else { return }
        notifySectionMovedFrom(section, to: newSection)
    }
    
    func dataSourceDidReloadData(_ dataSource: DataSource) {
        guard _wrappedDatasourceIsLoaded() else { return }
        notifyDidReloadData()
    }
    
    func dataSource(_ dataSource: DataSource, performBatchUpdate update: @escaping () -> Void,  completion: @escaping (Bool) -> Void ) {
        guard _wrappedDatasourceIsLoaded() else { return }
        notifyBatchUpdate(update) { (finished) in
            completion(finished)
            
        }
    }
}
