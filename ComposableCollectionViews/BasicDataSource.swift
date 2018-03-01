//
//  BasicDataSource.swift
//  ComposableCollectionViews
//
//  Created by Michael Simons on 3/1/18.
//  Copyright © 2018 Fermented Code, LLC. All rights reserved.
//

import Foundation

internal class BasicDataSource: DataSource {

    weak var delegate: DataSourceDelegate? = nil

    fileprivate let _items: [AnyObject]

    init(items: [AnyObject]) {
        _items = items
    }

    func itemAtIndexPath(_ indexPath: IndexPath) -> Any {
        guard (indexPath as NSIndexPath).section == 0 else { fatalError("BasicDataSource only supports 1 section") }
        return _items[(indexPath as NSIndexPath).item]
    }

    func numberOfItemsInSection(_ section: Int) -> Int {
        return _items.count
    }

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfItemsInAllSections() -> Int {
        return _items.count
    }
}
