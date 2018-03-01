//
//  ComposedDataSource.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import Foundation
import UIKit

internal typealias Section = Int

/**
Class for mapping between global and local index paths for datasource within a composed datasource

          ┌────────────────┐
          │                │
          │   DataSource   │
          │                │
          └────────────────┘
                ▲
                │
    ┌──────────────────────────┐
    │                          │╲
    │ CollectionViewDataSource │──┼───┐
    │                          │╱     │
    └──────────────────────────┘      │
                  ▲                   │
                  │                   │
                  │                   │
┌───────────────────────────────────┐ │
│                                   │ │
│ ComposedCollectionViewDataSource  │ │
│                                   │ │
└───────────────────────────────────┘ │
                  ┼                   │
                  │                   │
                  └───────────────────┘
*/




internal class ComposedCollectionViewDataSource {

    weak var delegate: DataSourceDelegate? = nil

    fileprivate var _mappingToDatasources = NSMapTable<AnyObject, ComposedDataSourceMapping>(keyOptions: NSMapTableObjectPointerPersonality, valueOptions: NSMapTableStrongMemory)
    fileprivate var _dataSources: [CollectionViewDataSource] = []
    fileprivate var _mappings: [ComposedDataSourceMapping] = []
    fileprivate var _globalSectionToMappings: [Section:ComposedDataSourceMapping] = [:]

    func addDataSource(_ dataSource: CollectionViewDataSource) {

        dataSource.delegate = self

        let mapping = ComposedDataSourceMapping(dataSource: dataSource)

        _mappingToDatasources.setObject(mapping, forKey: dataSource)

        _mappings.append(mapping)
        _dataSources.append(dataSource)

        _updateMappings()
    }

    func indexPathInDataSource(_ dataSource: CollectionViewDataSource, forGlobalIndexPath indexPath: IndexPath) -> IndexPath? {
        _updateMappings()

        let mapping = _mappingForDataSource(dataSource)

        guard mapping.containsGlobalSection(indexPath.section) else {return nil}

        return mapping.localIndexPathForGlobalIndexPath(indexPath)
    }

    fileprivate func _mappingForGlobalSection(_ globalSection: Section) -> ComposedDataSourceMapping {
        guard let mapping = _globalSectionToMappings[globalSection] else { fatalError("Asking for mapping that doesnt exist") }

        return mapping
    }

    fileprivate func _updateMappings() {

        var startingSection = 0

        for mapping in _mappings {
            let nextSection = mapping.updateMappingsStartingWithGlobalSection(startingSection)

            for globalSection in startingSection..<nextSection {
                _globalSectionToMappings[globalSection] = mapping
            }

            startingSection = nextSection
        }
    }

    fileprivate func _mappingForDataSource(_ dataSource: CollectionViewDataSource) -> ComposedDataSourceMapping {
        guard let mapping = _mappingToDatasources.object(forKey: dataSource) else {preconditionFailure("invalid mapping")}
        return mapping
    }

    fileprivate func _globalPathsFromLocalPaths(_ localIndexPaths: [IndexPath], forDataSource dataSource: CollectionViewDataSource) -> [IndexPath] {
        let mapping = _mappingForDataSource(dataSource)
        let globalIndexPaths = mapping.globalIndexPathsForLocalIndexPaths(localIndexPaths)
        return globalIndexPaths
    }

    fileprivate func _globalSectionsFromLocalSections(_ localSections: IndexSet, forDataSource dataSource: CollectionViewDataSource) -> IndexSet {
        let mapping = _mappingForDataSource(dataSource)

        let globalSections = NSMutableIndexSet()

        for localSection in localSections {
            let globalSection = mapping.globalSectionForLocalSection(localSection)
            globalSections.add(globalSection)
        }


        return globalSections as IndexSet
    }
}


extension ComposedCollectionViewDataSource: DataSource {

    func numberOfSections() -> Int {
        _updateMappings()

        let sectionCounts = _dataSources.map { $0.numberOfSections() }
        let totalSections = sectionCounts.reduce(0) { return $0 + $1 }
        return totalSections
    }

    func numberOfItemsInAllSections() -> Int {
        _updateMappings()

        let itemCounts = _dataSources.map { $0.numberOfItemsInAllSections() }
        let totalItems = itemCounts.reduce(0) { return $0 + $1 }
        return totalItems
    }

    func numberOfItemsInSection(_ globalSection: Int) -> Int {
        _updateMappings()

        let mapping = _mappingForGlobalSection(globalSection)
        let dataSource = mapping.dataSource

        let localSection = mapping.localSectionForGlobalSection(globalSection)

        return dataSource.numberOfItemsInSection(localSection)
    }

    func itemAtIndexPath(_ globalIndexPath: IndexPath) -> Any {

        let mapping = _mappingForGlobalSection(globalIndexPath.section)
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPathForGlobalIndexPath(globalIndexPath)

        return dataSource.itemAtIndexPath(localIndexPath)
    }

}

extension ComposedCollectionViewDataSource: RefreshableDataSource {
    func refreshContent(_ completion:(() -> Void)? = nil) {

        DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async { () -> Void in
            let group = DispatchGroup()

            for dataSource in self._dataSources {
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

extension ComposedCollectionViewDataSource: CollectionViewDataSource {

    func registerReusableViewsWithCollectionView(_ collectionView: UICollectionView) {
        for dataSource in _dataSources {
            dataSource.registerReusableViewsWithCollectionView(collectionView)
        }
    }

    func cellProvider(_ cellProvider: CollectionViewCellProvider, cellForItemAtIndexPath globalIndexPath: IndexPath) -> UICollectionViewCell {
        let mapping = _mappingForGlobalSection(globalIndexPath.section)
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPathForGlobalIndexPath(globalIndexPath)

        let wrappedCellProvider = MappedCollectionViewCellProvider(provider: cellProvider, dataSourceMapping: mapping)


        return dataSource.cellProvider(wrappedCellProvider, cellForItemAtIndexPath: localIndexPath)
    }

    func cellProvider(_ cellProvider: CollectionViewCellProvider, viewForSupplementaryElementOfKind kind: String, atIndexPath globalIndexPath: IndexPath) -> UICollectionReusableView {
        let mapping = _mappingForGlobalSection((globalIndexPath as NSIndexPath).section)
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPathForGlobalIndexPath(globalIndexPath)

        let wrappedCellProvider = MappedCollectionViewCellProvider(provider: cellProvider, dataSourceMapping: mapping)


        return dataSource.cellProvider(wrappedCellProvider, viewForSupplementaryElementOfKind: kind, atIndexPath: localIndexPath)
    }
    
    func updateCell(_ cell: UICollectionViewCell, withItem item: Any, atIndexPath indexPath: IndexPath) {
        
        let mapping = _mappingForGlobalSection( (indexPath as NSIndexPath).section )
        let dataSource = mapping.dataSource
        let localIndexPath = mapping.localIndexPathForGlobalIndexPath(indexPath)

        dataSource.updateCell(cell, withItem: item, atIndexPath: localIndexPath)
    }


}

extension ComposedCollectionViewDataSource: DataSourceDelegate {
    func dataSource(_ dataSource: DataSource, didInsertItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard let dataSource = dataSource as? CollectionViewDataSource else {return}

        let globalIndexPaths = _globalPathsFromLocalPaths(indexPaths, forDataSource: dataSource)
        notifyItemsInsertedAtIndexPaths(globalIndexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRemoveItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard let dataSource = dataSource as? CollectionViewDataSource else {return}

        let globalIndexPaths = _globalPathsFromLocalPaths(indexPaths, forDataSource: dataSource)
        notifyItemsRemovedAtIndexPaths(globalIndexPaths)
    }

    func dataSource(_ dataSource: DataSource, didRefreshItemsAtIndexPaths indexPaths: [IndexPath]) {
        guard let dataSource = dataSource as? CollectionViewDataSource else {return}
        
        let globalIndexPaths = _globalPathsFromLocalPaths(indexPaths, forDataSource: dataSource)
        notifyItemsRefreshedAtIndexPaths(globalIndexPaths)
    }
    
    
    func dataSource(_ dataSource: DataSource, didRefreshIndexPathsWithItems items: [IndexPath : Any]) {
        guard let dataSource = dataSource as? CollectionViewDataSource else {return}

        
        let globalItemPairs = items.flatMap { (index, item) -> (IndexPath, Any) in
            return (_globalPathsFromLocalPaths([index], forDataSource: dataSource).first!, item)
        }
        
        var globalItems = [IndexPath : Any]()
        
        for pair in globalItemPairs {
            globalItems[pair.0] = pair.1
        }
        
        notifyItemsAndIndexPathsRefreshed(globalItems)
    }
    
    

    func dataSource(_ dataSource: DataSource, didMoveItemAtIndexPath fromIndexPath: IndexPath, toIndexPath newIndexPath: IndexPath) {
        guard let dataSource = dataSource as? CollectionViewDataSource else {return}

        let mapping = _mappingForDataSource(dataSource)
        let globalFromPath = mapping.globalIndexPathForLocalIndexPath(fromIndexPath)
        let globalToPath = mapping.globalIndexPathForLocalIndexPath(newIndexPath)

        notifyItemMovedFromIndexPath(globalFromPath, toIndexPath: globalToPath)
    }

    func dataSource(_ dataSource: DataSource, didInsertSections sections: IndexSet) {
        guard let dataSource = dataSource as? CollectionViewDataSource else {return}
        
        _updateMappings()

        let globalSections = _globalSectionsFromLocalSections(sections, forDataSource: dataSource)
        notifySectionsInserted(globalSections)
    }

    func dataSource(_ dataSource: DataSource, didRemoveSections sections: IndexSet) {
        guard let dataSource = dataSource as? CollectionViewDataSource else {return}

        _updateMappings()
        
        let globalSections = _globalSectionsFromLocalSections(sections, forDataSource: dataSource)
        notifySectionsRemoved(globalSections)
    }

    func dataSource(_ dataSource: DataSource, didRefreshSections sections: IndexSet) {
        guard let dataSource = dataSource as? CollectionViewDataSource else {return}

        let globalSections = _globalSectionsFromLocalSections(sections, forDataSource: dataSource)
        notifySectionsRefreshed(globalSections)
        _updateMappings()
    }

    func dataSource(_ dataSource: DataSource, didMoveSection section: Section, toSection newSection: Section) {
        guard let dataSource = dataSource as? CollectionViewDataSource else {return}

        let mapping = _mappingForDataSource(dataSource)
        let globalFromSection = mapping.globalSectionForLocalSection(section)
        let globalToSection = mapping.globalSectionForLocalSection(newSection)
     
        _updateMappings()

        notifySectionMovedFrom(globalFromSection, to: globalToSection)
    }

    func dataSourceDidReloadData(_ dataSource: DataSource) {
        notifyDidReloadData()
    }

    func dataSource(_ dataSource: DataSource, performBatchUpdate update: @escaping () -> Void, completion: @escaping (Bool) -> Void ) {
        notifyBatchUpdate(update, completion: completion)
    }
}
