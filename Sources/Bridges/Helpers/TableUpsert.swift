//
//  TableUpsert.swift
//  Bridges
//
//  Created by Mihael Isaev on 05.11.2020.
//  Inspired by Ethan Lozano on 05.11.2020.
//

import NIO
import SwifQL

extension Table {
    fileprivate func buildUpsertQuery(
        schema: String?,
        insertionItems: Columns,
        updateItems: Columns,
        conflictColumn: Path.Column,
        returning: Bool
    ) -> SwifQLable {
        var query = SwifQL
            .insertInto(
                Path.Schema(schema).table(Self.tableName),
                fields: insertionItems.map { Path.Column($0.0) }
            )
            .values
            .values(insertionItems.map { $0.1 })
            .on.conflict(conflictColumn).do
        if updateItems.count > 0 {
            query = query.update.set[items: updateItems.map { Path.Column($0.name) == $0.value }]
        } else {
            query = query.nothing
        }
        guard returning else { return query }
        return query.returning.asterisk
    }
    
    fileprivate func buildUpsertQuery(
        schema: String?,
        insertionItems: Columns,
        updateItems: Columns,
        conflictConstraint: KeyPathLastPath,
        returning: Bool
    ) -> SwifQLable {
        let query = SwifQL
            .insertInto(
                Path.Schema(schema).table(Self.tableName),
                fields: insertionItems.map { Path.Column($0.0) }
            )
            .values
            .values(insertionItems.map { $0.1 })
            .on.conflict.on.constraint(conflictConstraint).do
            .update
            .set[items: updateItems.map { Path.Column($0.name) == $0.value }]
        guard returning else { return query }
        return query.returning.asterisk
    }
    
    // MARK: Standalone, conflict column
    
    public func upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: KeyPathLastPath...,
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(
            conflictColumn: conflictColumn,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: db,
            on: container)
    }
    
    public func upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: KeyPathLastPath...,
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _upsert(
            conflictColumn: conflictColumn,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: db,
            on: container)
    }
    
    ///
    
    public func upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(
            conflictColumn: conflictColumn,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: db,
            on: container)
    }
    
    public func upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _upsert(
            conflictColumn: conflictColumn,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: db,
            on: container)
    }
    
    ///
    
    public func upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: KeyPathLastPath...,
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(conflictColumn: conflictColumn, excluding: excluding, schema: schema, on: db, on: container)
    }
    
    public func upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: KeyPathLastPath...,
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _upsert(conflictColumn: conflictColumn, excluding: excluding, schema: schema, on: db, on: container)
    }
    
    ///
    
    public func upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(conflictColumn: conflictColumn, excluding: excluding, schema: schema, on: db, on: container)
    }
    
    public func upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _upsert(conflictColumn: conflictColumn, excluding: excluding, schema: schema, on: db, on: container)
    }
    
    ///
    
    private func _upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        schema: String?,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        guard let updateItems = allColumns(excluding: conflictColumn, excluding: excluding) else {
            return container.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        return buildUpsertQuery(
            schema: schema,
            insertionItems: allColumns(),
            updateItems: updateItems.0,
            conflictColumn: updateItems.1,
            returning: false
        )
        .execute(on: db, on: container)
        .transform(to: ())
    }
    
    private func _upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        schema: String?,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        guard let updateItems = allColumns(excluding: conflictColumn, excluding: excluding) else {
            return container.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        return buildUpsertQuery(
            schema: schema,
            insertionItems: allColumns(),
            updateItems: updateItems.0,
            conflictColumn: updateItems.1,
            returning: true
        )
        .execute(on: db, on: container)
        .all(decoding: Self.self)
        .flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
    
    // MARK: Standalone, conflict constraint
    
    public func upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: KeyPathLastPath...,
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(
            conflictConstraint: conflictConstraint,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: db,
            on: container)
    }
    
    public func upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: KeyPathLastPath...,
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _upsert(
            conflictConstraint: conflictConstraint,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: db,
            on: container)
    }
    
    ///
    
    public func upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(
            conflictConstraint: conflictConstraint,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: db,
            on: container)
    }
    
    public func upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _upsert(
            conflictConstraint: conflictConstraint,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: db,
            on: container)
    }
    
    ///
    
    public func upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: KeyPathLastPath...,
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(conflictConstraint: conflictConstraint, excluding: excluding, schema: schema, on: db, on: container)
    }
    
    public func upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: KeyPathLastPath...,
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _upsert(conflictConstraint: conflictConstraint, excluding: excluding, schema: schema, on: db, on: container)
    }
    
    ///
    
    public func upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(conflictConstraint: conflictConstraint, excluding: excluding, schema: schema, on: db, on: container)
    }
    
    public func upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _upsert(conflictConstraint: conflictConstraint, excluding: excluding, schema: schema, on: db, on: container)
    }
    
    ///
    
    private func _upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        schema: String?,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        buildUpsertQuery(
            schema: schema,
            insertionItems: allColumns(),
            updateItems: allColumns(excluding: excluding),
            conflictConstraint: conflictConstraint,
            returning: false
        )
        .execute(on: db, on: container)
        .transform(to: ())
    }
    
    private func _upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        schema: String?,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        buildUpsertQuery(
            schema: schema,
            insertionItems: allColumns(),
            updateItems: allColumns(excluding: excluding),
            conflictConstraint: conflictConstraint,
            returning: true
        )
        .execute(on: db, on: container)
        .all(decoding: Self.self)
        .flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
    
    // MARK: On connection, conflict column
    
    public func upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: KeyPathLastPath...,
        inSchema schema: Schemable.Type? = nil,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(
            conflictColumn: conflictColumn,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: conn
        )
    }
    
    public func upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: KeyPathLastPath...,
        inSchema schema: Schemable.Type? = nil,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        _upsert(
            conflictColumn: conflictColumn,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: conn
        )
    }
    
    ///
    
    public func upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        inSchema schema: Schemable.Type? = nil,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(
            conflictColumn: conflictColumn,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: conn
        )
    }
    
    public func upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        inSchema schema: Schemable.Type? = nil,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        _upsert(
            conflictColumn: conflictColumn,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: conn
        )
    }
    
    ///
    
    public func upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: KeyPathLastPath...,
        inSchema schema: String,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(conflictColumn: conflictColumn, excluding: excluding, schema: schema, on: conn)
    }
    
    public func upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: KeyPathLastPath...,
        inSchema schema: String,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        _upsert(conflictColumn: conflictColumn, excluding: excluding, schema: schema, on: conn)
    }
    
    ///
    
    public func upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        inSchema schema: String,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(conflictColumn: conflictColumn, excluding: excluding, schema: schema, on: conn)
    }
    
    public func upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        inSchema schema: String,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        _upsert(conflictColumn: conflictColumn, excluding: excluding, schema: schema, on: conn)
    }
    
    ///
    
    private func _upsertNonReturning<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        schema: String?,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        guard let updateItems = allColumns(excluding: conflictColumn, excluding: excluding) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        let query = buildUpsertQuery(
            schema: schema,
            insertionItems: allColumns(),
            updateItems: updateItems.0,
            conflictColumn: updateItems.1,
            returning: false
        )
        return conn.query(sql: query)
    }
    
    private func _upsert<Column: ColumnRepresentable>(
        conflictColumn: KeyPath<Self, Column>,
        excluding: [KeyPathLastPath],
        schema: String?,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        guard let updateItems = allColumns(excluding: conflictColumn, excluding: excluding) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        let query = buildUpsertQuery(
            schema: schema,
            insertionItems: allColumns(),
            updateItems: updateItems.0,
            conflictColumn: updateItems.1,
            returning: true
        )
        return conn.query(sql: query, decoding: Self.self).flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
    
    // MARK: On connection, conflict constraint
    
    public func upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: KeyPathLastPath...,
        inSchema schema: Schemable.Type? = nil,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(
            conflictConstraint: conflictConstraint,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: conn
        )
    }
    
    public func upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: KeyPathLastPath...,
        inSchema schema: Schemable.Type? = nil,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        _upsert(
            conflictConstraint: conflictConstraint,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: conn
        )
    }
    
    ///
    
    public func upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        inSchema schema: Schemable.Type? = nil,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(
            conflictConstraint: conflictConstraint,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: conn
        )
    }
    
    public func upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        inSchema schema: Schemable.Type? = nil,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        _upsert(
            conflictConstraint: conflictConstraint,
            excluding: excluding,
            schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName,
            on: conn
        )
    }
    
    ///
    
    public func upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: KeyPathLastPath...,
        inSchema schema: String,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(conflictConstraint: conflictConstraint, excluding: excluding, schema: schema, on: conn)
    }
    
    public func upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: KeyPathLastPath...,
        inSchema schema: String,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        _upsert(conflictConstraint: conflictConstraint, excluding: excluding, schema: schema, on: conn)
    }
    
    ///
    
    public func upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        inSchema schema: String,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        _upsertNonReturning(conflictConstraint: conflictConstraint, excluding: excluding, schema: schema, on: conn)
    }
    
    public func upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        inSchema schema: String,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        _upsert(conflictConstraint: conflictConstraint, excluding: excluding, schema: schema, on: conn)
    }
    
    ///
    
    private func _upsertNonReturning(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        schema: String?,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        let query = buildUpsertQuery(
            schema: schema,
            insertionItems: allColumns(),
            updateItems: allColumns(excluding: excluding),
            conflictConstraint: conflictConstraint,
            returning: false
        )
        return conn.query(sql: query)
    }
    
    private func _upsert(
        conflictConstraint: KeyPathLastPath,
        excluding: [KeyPathLastPath],
        schema: String?,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        let query = buildUpsertQuery(
            schema: schema,
            insertionItems: allColumns(),
            updateItems: allColumns(excluding: excluding),
            conflictConstraint: conflictConstraint,
            returning: true
        )
        return conn.query(sql: query, decoding: Self.self).flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
}
