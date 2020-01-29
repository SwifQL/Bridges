//
//  DropTableBuilder.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import SwifQL

public class DropTableBuilder<Table: BridgeTable>: SwifQLable {
    public var parts: [SwifQLPart] {
        var query = SwifQL.drop.table
        if shouldCheckIfExists {
            query = query.if.exists
        }
        query = query[any: Path.Table(Table.name)]
        return query.parts
    }
    
    var shouldCheckIfExists = false
    
    public init () {}
    
    public func checkIfExists() -> Self {
        shouldCheckIfExists = true
        return self
    }
}
