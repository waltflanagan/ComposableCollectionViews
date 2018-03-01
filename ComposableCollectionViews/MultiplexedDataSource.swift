//
//  MultiplexedDataSource.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import Foundation

class MultiplexedDataSource: DataSource {

    weak var delegate: DataSourceDelegate? = nil

    fileprivate let _datasources: [DataSource]

    internal var activeDataSource: DataSource

    init(datasources: [DataSource]) {
        guard let activeDataSource =  datasources.first else {preconditionFailure("datasources must have at least one datasource object in it")}
        _datasources = datasources

        self.activeDataSource = activeDataSource

        for datasource in datasources {
            datasource.delegate = self
        }

    }

    func selectDatasourceAtIndex(_ index: Int) {
        guard index < _datasources.count else {return}

        activeDataSource = _datasources[index]
        delegate?.dataSourceDidReloadData(self)
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> Any {
        return activeDataSource.itemAtIndexPath(indexPath)
    }

    func numberOfItemsInSection(_ section: Int) -> Int {
        return activeDataSource.numberOfItemsInSection(section)
    }

    func numberOfSections() -> Int {
        return activeDataSource.numberOfSections()
    }

    func numberOfItemsInAllSections() -> Int {
        return activeDataSource.numberOfItemsInAllSections()
    }

}


extension MultiplexedDataSource : RefreshableDataSource {
    func refreshContent(_ completion: (() -> Void)?) {
        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async { () -> Void in
            let group = DispatchGroup()

            for dataSource in self._datasources {
                guard let refreshable = dataSource as? RefreshableDataSource else { continue }

                group.enter()

                refreshable.refreshContent({ () -> Void in
                    group.leave()
                })
            }

            group.notify(queue: DispatchQueue.main, execute: { () -> Void in
                completion?()
            })
        }
    }
}

extension MultiplexedDataSource: DataSourceDelegate {
    func dataSource(_ dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}

        notifyItemsInsertedAtIndexPaths(indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}

        notifyItemsRemovedAtIndexPaths(indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}

        notifyItemsRefreshedAtIndexPaths(indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRefreshIndexPathsWithItems items: [IndexPath : Any]) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}
        
        notifyItemsAndIndexPathsRefreshed(items)
    }
    
    func dataSource(_ dataSource: DataSource, didMoveItemAtIndexPath fromIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}


        notifyItemMovedFromIndexPath(fromIndexPath, toIndexPath: newIndexPath)
    }

    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}

        notifySectionsInserted(sections)
    }

    func dataSource(_ dataSource: DataSource, didRemoveSections sections: IndexSet) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}

        notifySectionsRemoved(sections)
    }

    func dataSource(_ dataSource: DataSource, didRefreshSections sections: IndexSet) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}

        notifySectionsRefreshed(sections)
    }

    func dataSource(_ dataSource: DataSource, didMoveSection section: Section, toSection newSection: Section) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}

        notifySectionMovedFrom(section, to: newSection)
    }

    func dataSourceDidReloadData(_ dataSource: DataSource) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}

        notifyDidReloadData()
    }

    func dataSource(_ dataSource: DataSource, performBatchUpdate update: @escaping () -> Void,  completion: @escaping (Bool) -> Void ) {
        guard let dataSource = dataSource as? CollectionViewDataSource , dataSource === activeDataSource else {return}

        notifyBatchUpdate(update, completion: completion)
    }
}
