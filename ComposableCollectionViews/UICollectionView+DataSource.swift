//
//  UICollectionView+DataSource.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import UIKit


extension UICollectionViewController : DataSourceDelegate {
    func dataSource(_ dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [IndexPath]) {
        self.collectionView?.insertItems(at: indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [IndexPath]) {
        self.collectionView?.deleteItems(at: indexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [IndexPath]) {

        if let collectionViewDataSource = dataSource as? CollectionViewDataSource {
            for indexPath in indexPaths {
                if let cell = self.collectionView?.cellForItem(at: indexPath) {
                    
                    collectionViewDataSource.updateCell(cell, withItem: collectionViewDataSource.itemAtIndexPath(indexPath), atIndexPath: indexPath)
                }
            }
        } else {
            UIView.performWithoutAnimation { () -> Void in
                self.collectionView?.reloadItems(at: indexPaths)
            }
        }

    }
    
    func dataSource(_ dataSource: DataSource, didRefreshIndexPathsWithItems items: [IndexPath : Any]) {
        
        
        if let collectionViewDataSource = dataSource as? CollectionViewDataSource {
            for item in items {
                if let cell = self.collectionView?.cellForItem(at: item.0) {
                    collectionViewDataSource.updateCell(cell, withItem:item.1, atIndexPath: item.0)
                }
            }
        } else {
            UIView.performWithoutAnimation { () -> Void in
                let indexPaths = Array(items.keys)

                self.collectionView?.reloadItems(at: indexPaths)
            }
        }
    }

    func dataSource(_ dataSource: DataSource, didMoveItemAtIndexPath fromIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath) {
        self.collectionView?.moveItem(at: fromIndexPath, to: newIndexPath)
    }

    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
        self.collectionView?.insertSections(sections)
    }

    func dataSource(_ dataSource: DataSource, didRemoveSections sections: IndexSet) {
        self.collectionView?.deleteSections(sections)
    }

    func dataSource(_ dataSource: DataSource, didRefreshSections sections: IndexSet) {
        self.collectionView?.reloadSections(sections)
    }

    func dataSource(_ dataSource: DataSource, didMoveSection section: Section, toSection newSection: Section) {
        self.collectionView?.moveSection(section, toSection: newSection)
    }

    func dataSourceDidReloadData(_ dataSource: DataSource) {
        self.collectionView?.reloadData()
    }

    func dataSource(_ dataSource: DataSource, performBatchUpdate update: @escaping () -> Void,  completion: @escaping (Bool) -> Void ) {
        self.collectionView?.performBatchUpdates(update, completion: completion)
    }
}
