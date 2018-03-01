//
//  DataSource.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//


import Foundation

protocol DataSource : class {
    weak var delegate: DataSourceDelegate? { get set }
    func numberOfSections() -> Int
    func numberOfItemsInSection(_ section: Int) -> Int
    func numberOfItemsInAllSections() -> Int
    func itemAtIndexPath(_ indexPath: IndexPath) -> Any
}

protocol RefreshableDataSource: DataSource {
    func refreshContent(_ completion:(() -> Void)?)
}


extension DataSource {

    fileprivate func _mainThreadNotify(_ notify: @escaping () -> Void) {

        if Thread.isMainThread {
            notify()
        } else {
            DispatchQueue.main.async(execute: notify)
        }

    }

    internal func notifyItemsInsertedAtIndexPaths(_ indexPaths: [IndexPath]) {
        guard indexPaths.count > 0 else { return }
        _mainThreadNotify { self.delegate?.dataSource(self, didInsertItemsAtIndexPaths: indexPaths) }
    }

    internal func notifyItemsRemovedAtIndexPaths(_ indexPaths: [IndexPath]) {
        guard indexPaths.count > 0 else { return }
        _mainThreadNotify { self.delegate?.dataSource(self, didRemoveItemsAtIndexPaths: indexPaths) }
    }

    internal func notifyItemsRefreshedAtIndexPaths(_ indexPaths: [IndexPath]) {
        guard indexPaths.count > 0 else { return }
        _mainThreadNotify { self.delegate?.dataSource(self, didRefreshItemsAtIndexPaths: indexPaths) }
    }
    
    internal func notifyItemsAndIndexPathsRefreshed(_ indexesAndItems: [IndexPath: Any]) {
        guard indexesAndItems.count > 0 else { return }
        _mainThreadNotify { self.delegate?.dataSource(self, didRefreshIndexPathsWithItems: indexesAndItems) }
    }

    internal func notifyItemMovedFromIndexPath(_ fromIndexPath: IndexPath, toIndexPath toPath: IndexPath) {
        _mainThreadNotify { self.delegate?.dataSource(self, didMoveItemAtIndexPath: fromIndexPath, toIndexPath: toPath)}
    }

    internal func notifySectionsInserted(_ sections: IndexSet) {
        guard sections.count > 0 else { return }
        _mainThreadNotify { self.delegate?.dataSource(self, didInsertSections: sections) }
    }

    internal func notifySectionsRemoved(_ sections: IndexSet) {
        guard sections.count > 0 else { return }
        _mainThreadNotify { self.delegate?.dataSource(self, didRemoveSections: sections) }
    }

    internal func notifySectionsRefreshed(_ sections: IndexSet) {
        guard sections.count > 0 else { return }
        _mainThreadNotify { self.delegate?.dataSource(self, didRefreshSections: sections) }
    }

    internal func notifySectionMovedFrom(_ fromSection: Section, to toSection: Section) {
        _mainThreadNotify { self.delegate?.dataSource(self, didMoveSection: fromSection, toSection: toSection) }
    }

    internal func notifyDidReloadData() {
        _mainThreadNotify { self.delegate?.dataSourceDidReloadData(self) }
    }

    internal func notifyBatchUpdate(_ update:@escaping () -> Void, completion: @escaping (Bool) -> Void) {
        _mainThreadNotify { self.delegate?.dataSource(self, performBatchUpdate: update, completion: completion) }
    }

}


protocol DataSourceDelegate: class {

    func dataSource(_ dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [IndexPath])
    func dataSource(_ dataSource: DataSource, didRefreshIndexPathsWithItems items: [IndexPath: Any])
    func dataSource(_ dataSource: DataSource, didMoveItemAtIndexPath fromIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath)

    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didRemoveSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didRefreshSections sections: IndexSet)
    func dataSource(_ dataSource: DataSource, didMoveSection section: Section, toSection newSection: Section)

    func dataSourceDidReloadData(_ dataSource: DataSource)
    func dataSource(_ dataSource: DataSource, performBatchUpdate update: @escaping () -> Void,  completion: @escaping (Bool) -> Void )

}
