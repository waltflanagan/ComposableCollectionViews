//
//  ComposedDataSourceMapping.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import Foundation


/**
Class for composing multiple data sources into a single one to be displayed in a single collection view.


Inspired by [Advanced User Interfaces with UICollectionView](https://developer.apple.com/videos/wwdc/2014/#232)
and
[sample code](https://github.com/zwaldowski/AdvancedCollectionView)
*/
internal class ComposedDataSourceMapping {

    internal let dataSource: CollectionViewDataSource
    internal var sectionCount: Int { return dataSource.numberOfSections() }

    fileprivate var _globalToLocalSections = [Section:Section]()
    fileprivate var _localToGlobalSections = [Section:Section]()

    init(dataSource: CollectionViewDataSource) {
        self.dataSource = dataSource
    }

    func containsGlobalSection(_ globalSection: Section) -> Bool {
        return _globalToLocalSections[globalSection] != nil
    }

    func localSectionForGlobalSection(_ globalSection: Section) -> Section {
        guard let localSection = _globalToLocalSections[globalSection] else {
            assertionFailure("globalSection \(globalSection) not found in _globalToLocalSections: \(_globalToLocalSections)")
            return 0
        }
        return localSection
    }

    func globalSectionForLocalSection(_ localSection: Section) -> Section {
        guard let globalSection = _localToGlobalSections[localSection] else {
            assertionFailure("localsection \(localSection) not found in _localToGlobalSections: \(_localToGlobalSections)")
            return 0
        }
        return globalSection
    }

    func localIndexPathForGlobalIndexPath(_ globalIndexPath: IndexPath) -> IndexPath {
        let localSection = self.localSectionForGlobalSection( (globalIndexPath as NSIndexPath).section )
        return IndexPath(item: (globalIndexPath as NSIndexPath).item, section: localSection)
    }

    func globalIndexPathForLocalIndexPath(_ localIndexPath: IndexPath) -> IndexPath {
        let globalSection = self.globalSectionForLocalSection( (localIndexPath as NSIndexPath).section )
        return IndexPath(item: (localIndexPath as NSIndexPath).item, section: globalSection)
    }

    func localIndexPathsForGlobalIndexPaths(_ globalIndexPaths: [IndexPath]) -> [IndexPath] {
        var localIndexPaths = [IndexPath]()

        for path in globalIndexPaths {
            let localPath = localIndexPathForGlobalIndexPath(path)
            localIndexPaths.append(localPath)
        }

        return localIndexPaths
    }

    func globalIndexPathsForLocalIndexPaths(_ localIndexPaths: [IndexPath]) -> [IndexPath] {
        var globalIndexPaths = [IndexPath]()

        for localPath in localIndexPaths {
            let globalPath = globalIndexPathForLocalIndexPath(localPath)
            globalIndexPaths.append(globalPath)
        }

        return globalIndexPaths
    }

    func updateMappingsStartingWithGlobalSection(_ globalStartingSection: Section) -> Section {
        _localToGlobalSections.removeAll()
        _globalToLocalSections.removeAll()

        var lastSection = globalStartingSection

        for localSection in 0..<sectionCount {
            self.addMappingFromGlobalSection(lastSection, toLocalSection: localSection)
            lastSection += 1
        }

        return lastSection
    }

    fileprivate func addMappingFromGlobalSection(_ globalSection: Section, toLocalSection localSection: Section) {
        assert(_localToGlobalSections[localSection] == nil,"collision while trying to add to a mapping")

        _globalToLocalSections[globalSection] = localSection
        _localToGlobalSections[localSection] = globalSection

    }
}

