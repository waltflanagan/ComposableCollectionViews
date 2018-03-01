//
//  CoreDataDataSource.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//


import UIKit
import CoreData


internal class CoreDataDataSource<FetchType: NSFetchRequestResult>: NSObject,  DataSource {

    weak var delegate: DataSourceDelegate? = nil

    fileprivate let _frc: NSFetchedResultsController<FetchType>
    fileprivate var _adapter: CoreDataDataSourceAdapter?

    init(fetchRequest: NSFetchRequest<FetchType>, objectContext: NSManagedObjectContext) {

        _frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: objectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        super.init()



        if let collectionViewDataSource = self as? CollectionViewDataSource {
            _adapter = CoreDataDataSourceAdapter(datasource: collectionViewDataSource, frc: _frc as! NSFetchedResultsController<NSManagedObject>)
        }

        do {
            try _frc.performFetch()
        } catch {
            fatalError("Unable to fetch from frc")
        }
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> Any {
        return _frc.object(at: indexPath)
    }

    func numberOfItemsInSection(_ section: Int) -> Int {
        guard let sectionInfo = _frc.sections?[section] else {
            return 0
        }

        //WORKAROUND:  for http://www.openradar.me/15262692
        // This fixes a crash when importing all the things on a fresh app install.  An empty CollectionView will as the delegate for the # of objects if it doesnt know yet.  This causes the bug.
        // At time of writing, this crashes the Recipes collection view if anything triggers its FRC to update things.
//        if let adapter = _adapter where adapter.changesPending() {
//            return adapter.prechangeNumberOfItemsInSection(section)
//        }

        

        return sectionInfo.numberOfObjects
    }

    func numberOfSections() -> Int {
        return _frc.sections?.count ?? 0
    }

    func numberOfItemsInAllSections() -> Int {
        guard let sections = _frc.sections else { return 0 }

        let itemCounts = sections.map { $0.numberOfObjects }
        let totalItems = itemCounts.reduce(0) { return $0 + $1 }
        return totalItems
    }
}


class CoreDataDataSourceAdapter: NSObject, NSFetchedResultsControllerDelegate {
    
    fileprivate let datasource: CollectionViewDataSource
    
    init(datasource: CollectionViewDataSource, frc: NSFetchedResultsController<NSManagedObject>) {
        self.datasource = datasource
        super.init()
        frc.delegate = self
    }
    
    fileprivate typealias SectionChangeTuple = (changeType: NSFetchedResultsChangeType, sectionIndex: Int)
    fileprivate var sectionChanges = [SectionChangeTuple]()
    
    fileprivate typealias ObjectChangeTuple = (changeType: NSFetchedResultsChangeType, indexPaths: [IndexPath])
    fileprivate var objectChanges = [ObjectChangeTuple]()
    
    fileprivate var updatedObjects = [IndexPath: AnyObject]()
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.sectionChanges.removeAll()
        self.objectChanges.removeAll()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                                     atSectionIndex sectionIndex: Int,
                                             for changeType: NSFetchedResultsChangeType) {
        self.sectionChanges.append((changeType, sectionIndex))
    }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
                        at indexPath: IndexPath?,
                                    for changeType: NSFetchedResultsChangeType,
                                                  newIndexPath: IndexPath?) {
        
        switch changeType {
        case .insert:
            if let insertIndexPath = newIndexPath {
                self.objectChanges.append((changeType, [insertIndexPath]))
            }
        case .delete:
            if let deleteIndexPath = indexPath {
                self.objectChanges.append((changeType, [deleteIndexPath]))
            }
        case .update:
            if let indexPath = indexPath {
                updatedObjects[indexPath] = anObject as AnyObject?
                self.objectChanges.append((changeType, [indexPath]))
            }
        case .move:
            if let old = indexPath, let new = newIndexPath {
                
                if new != old {
                    self.objectChanges.append((changeType, [old, new]))
                } else {
                    self.objectChanges.append((.update, [new]))
                }
                
            }
        }
        
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {
        return sectionName
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        let changes = self.objectChanges
        let sectionChanges = self.sectionChanges
        let objects = updatedObjects

        datasource.notifyBatchUpdate({ [weak self] () -> Void in

            self?.applyObjectChanges(changes, updatedObjects: objects)
            self?.applySectionChanges(sectionChanges)

            },
            completion: { [weak self] (finished) -> Void in

                if sectionChanges.count > 0 {
                    // if sections have changed, reload to update supplementary views
                    self?.datasource.notifyDidReloadData()
                }
            })


        self.sectionChanges.removeAll()
        self.objectChanges.removeAll()
        self.updatedObjects.removeAll()
    }


    fileprivate func applyObjectChanges( _ objectChanges: [ObjectChangeTuple], updatedObjects: [IndexPath: AnyObject]) {

        for (changeType, indexes) in objectChanges {

            switch changeType {
            case .insert: datasource.notifyItemsInsertedAtIndexPaths(indexes)
            case .delete: datasource.notifyItemsRemovedAtIndexPaths(indexes)
            case .update:
                let changedObjectsArray = updatedObjects.filter { indexes.contains($0.0) }
                
                var changedObjects = [IndexPath: Any]()
                for object in changedObjectsArray {
                    changedObjects[object.0] = object.1
                }
               
               datasource.notifyItemsAndIndexPathsRefreshed(changedObjects)

            case .move:
                if let from = indexes.first, let to = indexes.last {
                    datasource.notifyItemsRemovedAtIndexPaths([from])
                    datasource.notifyItemsInsertedAtIndexPaths([to])
                }
            }
        }

    }

    fileprivate func applySectionChanges(_ sectionChanges: [SectionChangeTuple]) {
        for (changeType, index) in sectionChanges {

            let section = IndexSet(integer: index)

            switch changeType {
            case .insert: datasource.notifySectionsInserted(section)
            case .delete: datasource.notifySectionsRemoved(section)
            case .update: datasource.notifySectionsRefreshed(section)
            case .move: break
            }
        }

    }

}
