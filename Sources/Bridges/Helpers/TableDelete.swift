//
//  TableDelete.swift
//  Bridges
//
//  Created by Mihael Isaev on 31.01.2020.
//

import NIO
import SwifQL

extension Table {
    fileprivate func buildDeleteQuery(items: Columns, where: SwifQLable) -> SwifQLable {
        SwifQL
            .delete(from: Self.table)
            .where(`where`)
            .returning
            .asterisk
    }
    
    // MARK: Standalone
    
    public func delete<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        guard let items = allColumns(excluding: keyColumn) else {
            return container.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        return buildDeleteQuery(items: items.0, where: items.1 == items.2)
            .execute(on: db, on: container)
            .transform(to: ())
    }
    
    // MARK: On connection
    
    public func delete<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        guard let items = allColumns(excluding: keyColumn) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        let query = buildDeleteQuery(items: items.0, where: items.1 == items.2)
        return conn.query(sql: query)
    }
}
