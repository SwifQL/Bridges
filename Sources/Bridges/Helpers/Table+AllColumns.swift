//
//  Table+AllColumns.swift
//  Bridges
//
//  Created by Mihael Isaev on 20.05.2020.
//

import Foundation

extension Table {
    typealias Columns = [(name: String, value: SwifQLable, isChanged: Bool)]
    
    func allColumns() -> Columns {
        columns.compactMap {
            let value: SwifQLable
            if let v = $0.property.inputValue as? SwifQLPart {
                value = SwifQLableParts(parts: [v])
            } else if let v = $0.property.inputValue as? SwifQLable {
                value = v
            } else if let v = $0.property.inputValue as? Bool {
                value = SwifQLBool(v)
            } else {
                return nil
            }
            return ($0.name.label, value, $0.property.isChanged)
        }
    }
    
    func allColumns<Column: ColumnRepresentable>(
        excluding keyColumn: KeyPath<Self, Column>
    ) -> (columns: Columns, columnKey: Path.Column, columnValue: SwifQLable)? {
        let items = allColumns()
        let keyColumnName = Self.key(for: keyColumn)
        guard let keyColumnValue = items.first(where: { $0.0 == keyColumnName })?.1 else {
            return nil
        }
        return (items.filter { $0.0 != keyColumnName && $0.2 }, Path.Column(keyColumnName), keyColumnValue)
    }
}
