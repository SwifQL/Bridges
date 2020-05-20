//
//  TableUpdate.swift
//  Bridges
//
//  Created by Mihael Isaev on 31.01.2020.
//

import Logging
import NIO
import SwifQL

extension Table {
    fileprivate func buildUpdateQuery(items: Columns, where: SwifQLable) -> SwifQLable {
        SwifQL
            .update(Self.table)
            .set[items: items.map { Path.Column($0.name) == $0.value }]
            .where(`where`)
            .returning
            .asterisk
    }
    
    // MARK: Standalone
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @escaping () throws -> Void
    ) -> EventLoopFuture<Self> {
        container.eventLoop.future().flatMapThrowing {
            try preActions()
        }.flatMap {
            self.update(on: keyColumn, on: db, on: container)
        }
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @escaping (Self) throws -> Void
    ) -> EventLoopFuture<Self> {
        container.eventLoop.future().flatMapThrowing {
            try preActions(self)
        }.flatMap {
            self.update(on: keyColumn, on: db, on: container)
        }
    }
    
    public func update<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: () -> EventLoopFuture<T>
    ) -> EventLoopFuture<Self> {
        preActions().flatMap { _ in
            self.update(on: keyColumn, on: db, on: container)
        }
    }
    
    public func update<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: (Self) -> EventLoopFuture<T>
    ) -> EventLoopFuture<Self> {
        preActions(self).flatMap { _ in
            self.update(on: keyColumn, on: db, on: container)
        }
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        guard let items = allColumns(excluding: keyColumn) else {
            return container.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        return buildUpdateQuery(items: items.0, where: items.1 == items.2)
            .execute(on: db, on: container)
            .all(decoding: Self.self)
            .flatMapThrowing { rows in
                guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
                return row
            }
    }
    
    public func update(
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        where predicates: SwifQLable
    ) -> EventLoopFuture<Self> {
        buildUpdateQuery(items: allColumns(), where: predicates)
            .execute(on: db, on: container)
            .all(decoding: Self.self)
            .flatMapThrowing { rows in
                guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
                return row
            }
    }
    
    // MARK: On connection
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: @escaping () throws -> Void
    ) -> EventLoopFuture<Self> {
        conn.eventLoop.future().flatMapThrowing {
            try preActions()
        }.flatMap {
            self.update(on: keyColumn, on: conn)
        }
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: @escaping (Self) throws -> Void
    ) -> EventLoopFuture<Self> {
        conn.eventLoop.future().flatMapThrowing {
            try preActions(self)
        }.flatMap {
            self.update(on: keyColumn, on: conn)
        }
    }
    
    public func update<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: () -> EventLoopFuture<T>
    ) -> EventLoopFuture<Self> {
        preActions().flatMap { _ in
            self.update(on: keyColumn, on: conn)
        }
    }
    
    public func update<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: (Self) -> EventLoopFuture<T>
    ) -> EventLoopFuture<Self> {
        preActions(self).flatMap { _ in
            self.update(on: keyColumn, on: conn)
        }
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        guard let items = allColumns(excluding: keyColumn) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        let query = buildUpdateQuery(items: items.0, where: items.1 == items.2)
        return conn.query(sql: query, decoding: Self.self).flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
    
    public func update(on conn: BridgeConnection, where predicates: SwifQLable) -> EventLoopFuture<Void> {
        conn.query(sql: buildUpdateQuery(items: allColumns(), where: predicates))
    }
}

fileprivate func error(_ logger: Logger) {
    logger.error(.init(stringLiteral: "Query doesn't work with non-generic database identifier. Please initialize AnyDatabaseIdentifier as MySQL or Postgres explicitly."))
}
