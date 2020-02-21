//
//  TableUpdate.swift
//  Bridges
//
//  Created by Mihael Isaev on 31.01.2020.
//

import NIO
import SwifQL

extension Table {
    public func update<Column>(on keyColumn: KeyPath<Self, Column>, on conn: BridgeConnection) -> EventLoopFuture<Self> where Column: ColumnRepresentable {
        var items: [(String, SwifQLable, Bool)] = columns.compactMap {
            let value: SwifQLable
            if let v = $0.1.inputValue as? SwifQLable {
                value = v
            } else if let v = $0.1.inputValue as? Bool {
                value = SwifQLBool(v)
            } else {
                return nil
            }
            return ($0.0, value, $0.1.isChanged)
        }
        let keyColumnName = Self.key(for: keyColumn)
        let keyColumn = Path.Column(keyColumnName)
        guard let keyColumnValue = items.first(where: { $0.0 == keyColumnName })?.1 else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        items = items.filter { $0.0 != keyColumnName && $0.2 }
        let query = SwifQL
            .update(Self.table)
            .set[items: items.map { Path.Column($0.0) == $0.1 }]
            .where(keyColumn == keyColumnValue)
            .returning
            .asterisk
        return conn.query(sql: query, decoding: Self.self).flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
    
    public func update(on conn: BridgeConnection, where predicates: SwifQLable) -> EventLoopFuture<Void> {
        let items: [(String, SwifQLable)] = columns.compactMap {
            guard let value = $0.1.inputValue as? SwifQLable else { return nil }
            return ($0.0, value)
        }
        let query = SwifQL
            .update(Self.table)
            .set[values: items.map { Path.Column($0.0) == $0.1 }]
            .where(predicates)
            .returning
            .asterisk
        return conn.query(sql: query)
    }
}
