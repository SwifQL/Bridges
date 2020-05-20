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
    typealias Items = [(String, SwifQLable, Bool)]
    
    func allItems() -> Items {
        columns.compactMap {
            let value: SwifQLable
            if let v = $0.property.inputValue as? SwifQLable {
                value = v
            } else if let v = $0.property.inputValue as? Bool {
                value = SwifQLBool(v)
            } else {
                return nil
            }
            return ($0.name.label, value, $0.property.isChanged)
        }
    }
    
    func allItems<Column>(
        excluding keyColumn: KeyPath<Self, Column>
    ) -> (Items, Path.Column, SwifQLable)? where Column: ColumnRepresentable {
        let items = allItems()
        let keyColumnName = Self.key(for: keyColumn)
        guard let keyColumnValue = items.first(where: { $0.0 == keyColumnName })?.1 else {
            return nil
        }
        return (items.filter { $0.0 != keyColumnName && $0.2 }, Path.Column(keyColumnName), keyColumnValue)
    }
    
    func buildUpdateQuery(items: Items, where: SwifQLable) -> SwifQLable {
        SwifQL
            .update(Self.table)
            .set[items: items.map { Path.Column($0.0) == $0.1 }]
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
        guard let items = allItems(excluding: keyColumn) else {
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
        buildUpdateQuery(items: allItems(), where: predicates)
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
        guard let items = allItems(excluding: keyColumn) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        let query = buildUpdateQuery(items: items.0, where: items.1 == items.2)
        return conn.query(sql: query, decoding: Self.self).flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
    
    public func update(on conn: BridgeConnection, where predicates: SwifQLable) -> EventLoopFuture<Void> {
        conn.query(sql: buildUpdateQuery(items: allItems(), where: predicates))
    }
}

fileprivate func error(_ logger: Logger) {
    logger.error(.init(stringLiteral: "Query doesn't work with non-generic database identifier. Please initialize AnyDatabaseIdentifier as MySQL or Postgres explicitly."))
}
