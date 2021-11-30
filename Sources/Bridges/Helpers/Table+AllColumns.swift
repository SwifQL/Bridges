//
//  Table+AllColumns.swift
//  Bridges
//
//  Created by Mihael Isaev on 20.05.2020.
//

import Foundation
import SwifQL
import Logging

extension Table {
    typealias Columns = [(name: String, value: SwifQLable, isChanged: Bool)]
    
    func allColumns(logger: Logger) -> Columns {
        columns.compactMap {
            guard let value = $0.property.inputValue?.swifQLable else {
                logger.debug("⚠️ Skipped column \($0.name) for \(Self.tableName) table cause it doesn't conform to SwifQLable")
                return nil
            }
            return ($0.name.label, value, $0.property.isChanged)
        }
    }
    
    func allColumns<Column: ColumnRepresentable>(
        excluding keyColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath] = [],
        logger: Logger
    ) -> (columns: Columns, columnKey: Path.Column, columnValue: SwifQLable)? {
        let items = allColumns(logger: logger)
        let keyColumnName = Self.key(for: keyColumn)
        guard let keyColumnValue = items.first(where: { $0.0 == keyColumnName })?.1 else {
            return nil
        }
        let excludingColumns: [String] = excluding.map { $0.lastPath } + [keyColumnName]
        return (
            items.filter { !excludingColumns.contains($0.0) && $0.2 },
            Path.Column(keyColumnName),
            keyColumnValue
        )
    }
    
    func allColumns(excluding: [KeyPathLastPath], logger: Logger) -> Columns {
        let items = allColumns(logger: logger)
        let excludingColumns: [String] = excluding.map { $0.lastPath }
        return items.filter { !excludingColumns.contains($0.0) && $0.2 }
    }
}
