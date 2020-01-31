//
//  TableDelete.swift
//  Bridges
//
//  Created by Mihael Isaev on 31.01.2020.
//

import NIO
import SwifQL

extension Table {
    public func delete<Column>(on keyColumn: KeyPath<Self, Column>, on conn: BridgeConnection) -> EventLoopFuture<Void> where Column: ColumnRepresentable {
        let items: [(String, SwifQLable)] = columns.compactMap {
            guard let value = $0.1.inputValue as? SwifQLable else { return nil }
            return ($0.0, value)
        }
        let keyColumnName = Self.key(for: keyColumn)
        let keyColumn = Path.Column(keyColumnName)
        guard let keyColumnValue = items.first(where: { $0.0 == keyColumnName })?.0 else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        let query = SwifQL
            .delete(from: Self.table)
            .where(keyColumn == keyColumnValue)
        return conn.query(sql: query)
    }
}
