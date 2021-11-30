//
//  TableDelete.swift
//  Bridges
//
//  Created by Mihael Isaev on 31.01.2020.
//

import NIO
import SwifQL

extension Table {
    fileprivate func buildDeleteQuery(items: Columns, where: SwifQLable, returning: Bool) -> SwifQLable {
        let query = SwifQL
            .delete(from: Self.table)
            .where(`where`)
        guard returning else { return query }
        return query.returning.asterisk
    }
    
    // MARK: Standalone
    
    public func deleteNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        guard let items = allColumns(excluding: keyColumn, logger: container.logger) else {
            return container.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        return buildDeleteQuery(items: items.0, where: items.1 == items.2, returning: false)
            .execute(on: db, on: container)
            .transform(to: ())
    }
    
    public func delete<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        guard let items = allColumns(excluding: keyColumn, logger: container.logger) else {
            return container.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        return buildDeleteQuery(items: items.0, where: items.1 == items.2, returning: true)
            .execute(on: db, on: container)
            .all(decoding: Self.self)
            .flatMapThrowing { rows in
                guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
                return row
            }
    }
    
    // MARK: On connection
    
    public func delete<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        guard let items = allColumns(excluding: keyColumn, logger: conn.logger) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        let query = buildDeleteQuery(items: items.0, where: items.1 == items.2, returning: false)
        return conn.query(sql: query)
    }
}
