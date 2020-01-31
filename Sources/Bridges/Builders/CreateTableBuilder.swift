//
//  CreateTableBuilder.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import SwifQL

public class CreateTableBuilder<Table: BridgeTable>: SwifQLable {
    public var parts: [SwifQLPart] {
        var query = SwifQL.create.table
        if shouldCheckIfNotExists {
            query = query.if.not.exists
        }
        query = query[any: Path.Table(Table.tableName)].newColumns(columns)
        return query.parts
    }
    
    var columns: [NewColumn] = []
    var shouldCheckIfNotExists = false
    
    public init () {}
    
    public func column(_ newColumn: NewColumn) -> Self {
        columns.append(newColumn)
        return self
    }
    
    // MARK: KeyPath
    
    public func column<V>(_ keyPath: KeyPath<Table, V>, _ type: SwifQL.`Type`) -> Self where V: ColumnRepresentable {
        column(keyPath, type: type, default: nil, constraints: [])
    }
    
    public func column<V>(_ keyPath: KeyPath<Table, V>, _ type: SwifQL.`Type`, _ constraints: Constraint...) -> Self where V: ColumnRepresentable {
        column(keyPath, type: type, default: nil, constraints: constraints)
    }
    
    public func column<V>(_ keyPath: KeyPath<Table, V>, _ type: SwifQL.`Type`, _ `default`: ColumnDefault, _ constraints: Constraint...) -> Self where V: ColumnRepresentable {
        column(keyPath, type: type, default: `default`, constraints: constraints)
    }
    
    public func column<V>(_ keyPath: KeyPath<Table, V>, type: SwifQL.`Type`, `default`: ColumnDefault?, constraints: [Constraint]) -> Self where V: ColumnRepresentable {
        column(Table.key(for: keyPath), type: type, default: `default`, constraints: constraints)
    }
    
    // MARK: String
    
    public func column(_ name: String, _ type: SwifQL.`Type`) -> Self {
        column(name, type: type, default: nil, constraints: [])
    }
    
    public func column(_ name: String, _ type: SwifQL.`Type`, _ constraints: Constraint...) -> Self {
        column(name, type: type, default: nil, constraints: constraints)
    }
    
    public func column(_ name: String, _ type: SwifQL.`Type`, _ `default`: ColumnDefault, _ constraints: Constraint...) -> Self {
        column(name, type: type, default: `default`, constraints: constraints)
    }
    
    public func column(_ name: String, type: SwifQL.`Type`, `default`: ColumnDefault?, constraints: [Constraint]) -> Self {
        let newColumn = NewColumn(name, type)
        if let expression = `default`?.query {
            newColumn.default(expression: expression)
        }
        constraints.forEach {
            newColumn.constraint(expression: $0.query)
        }
        columns.append(newColumn)
        return self
    }
    
    public func checkIfNotExists() -> Self {
        shouldCheckIfNotExists = true
        return self
    }
}
