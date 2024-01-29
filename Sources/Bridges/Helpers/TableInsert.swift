//
//  TableCreate.swift
//  Bridges
//
//  Created by Mihael Isaev on 31.01.2020.
//

import NIO
import SwifQL

extension Table {
    fileprivate func buildInsertQuery(schema: String?, items: Columns, returning: Bool) -> SwifQLable {
        let query = SwifQL
            .insertInto(
                Path.Schema(schema).table(Self.tableName),
                fields: items.map { Path.Column($0.0) }
            )
            .values
            .values(items.map { $0.1 })
        guard returning else { return query }
        return query.returning.asterisk
    }
    
    // MARK: Standalone
    
    public func insertNonReturning(
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _insertNonReturning(schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName, on: db, on: container)
    }
    
    public func insert(
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _insert(schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName, on: db, on: container)
    }
    
    ///
    
    public func insertNonReturning(
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        _insertNonReturning(schema: schema, on: db, on: container)
    }
    
    public func insert(
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        _insert(schema: schema, on: db, on: container)
    }
    
    ///
    
    private func _insertNonReturning(
        schema: String?,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        buildInsertQuery(schema: schema, items: allColumns(logger: container.logger), returning: false)
            .execute(on: db, on: container)
            .transform(to: ())
    }
    
    private func _insert(
        schema: String?,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        buildInsertQuery(schema: schema, items: allColumns(logger: container.logger), returning: true)
            .execute(on: db, on: container)
            .all(decoding: Self.self)
            .flatMapThrowing { rows in
                guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
                return row
            }
    }
    
    // MARK: On connection
    
    public func insertNonReturning(inSchema schema: Schemable.Type? = nil, on conn: BridgeConnection) -> EventLoopFuture<Void> {
        _insertNonReturning(schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName, on: conn)
    }
    
    public func insert(inSchema schema: Schemable.Type? = nil, on conn: BridgeConnection) -> EventLoopFuture<Self> {
        _insert(schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName, on: conn)
    }
    
    ///
    
    public func insertNonReturning(inSchema schema: String, on conn: BridgeConnection) -> EventLoopFuture<Void> {
        _insertNonReturning(schema: schema, on: conn)
    }
    
    public func insert(inSchema schema: String, on conn: BridgeConnection) -> EventLoopFuture<Self> {
        _insert(schema: schema, on: conn)
    }
    
    ///
    
    private func _insertNonReturning(schema: String?, on conn: BridgeConnection) -> EventLoopFuture<Void> {
        let query = buildInsertQuery(schema: schema, items: allColumns(logger: conn.logger), returning: false)
        return conn.query(sql: query)
    }
    
    private func _insert(schema: String?, on conn: BridgeConnection) -> EventLoopFuture<Self> {
        let query = buildInsertQuery(schema: schema, items: allColumns(logger: conn.logger), returning: true)
        return conn.query(sql: query, decoding: Self.self).flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
    
    public func insertNonReturning(
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) async throws {
        try await _insertNonReturning(schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName, on: db, on: container)
    }
    
    public func insert(
        inSchema schema: Schemable.Type? = nil,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) async throws -> EventLoopFuture<Self> {
        _insert(schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName, on: db, on: container)
    }
    
    ///
    
    public func insertNonReturning(
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) async throws -> EventLoopFuture<Void> {
        _insertNonReturning(schema: schema, on: db, on: container)
    }
    
    public func insert(
        inSchema schema: String,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) async throws -> EventLoopFuture<Self> {
        _insert(schema: schema, on: db, on: container)
    }
    
    
    private func _insertNonReturning(
        schema: String?,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) async throws {
        _ = try await buildInsertQuery(schema: schema, items: allColumns(logger: container.logger), returning: false)
            .execute(on: db, on: container)
    }
    
    private func _insert(
        schema: String?,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) async throws -> Self {
        guard let first = try await buildInsertQuery(schema: schema, items: allColumns(logger: container.logger), returning: true)
            .execute(on: db, on: container)
            .all(decoding: Self.self).first
        else {
            throw BridgesError.failedToDecodeWithReturning
        }
        return first
    }
    
    // MARK: On connection
    
    public func insertNonReturning(inSchema schema: Schemable.Type? = nil, on conn: BridgeConnection) async throws {
        try await _insertNonReturning(schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName, on: conn)
    }
    
    public func insert(inSchema schema: Schemable.Type? = nil, on conn: BridgeConnection) async throws -> Self {
        try await _insert(schema: schema?.schemaName ?? (Self.self as? Schemable.Type)?.schemaName, on: conn)
    }
    
    ///
    
    public func insertNonReturning(inSchema schema: String, on conn: BridgeConnection) async throws {
        try await _insertNonReturning(schema: schema, on: conn)
    }
    
    public func insert(inSchema schema: String, on conn: BridgeConnection) async throws -> Self {
        try await _insert(schema: schema, on: conn)
    }
    
    ///
    
    private func _insertNonReturning(schema: String?, on conn: BridgeConnection) async throws {
        let query = buildInsertQuery(schema: schema, items: allColumns(logger: conn.logger), returning: false)
        try await conn.query(sql: query)
    }
    
    private func _insert(schema: String?, on conn: BridgeConnection) async throws -> Self {
        let query = buildInsertQuery(schema: schema, items: allColumns(logger: conn.logger), returning: true)
        guard let first = try await conn.query(sql: query, decoding: Self.self).first
        else {
            throw BridgesError.failedToDecodeWithReturning
        }
        return first
    }
}

// MARK: Batch Insert

extension Array where Element: Table {
    public func batchInsert(inSchema schema: Schemable.Type? = nil, on conn: BridgeConnection) -> EventLoopFuture<Void> {
        guard count > 0 else { return conn.eventLoop.future() }
        return conn.query(sql: batchInsertQuery(schema: schema?.schemaName ?? (Element.self as? Schemable.Type)?.schemaName))
    }
    
    public func batchInsert(schema: String, on conn: BridgeConnection) -> EventLoopFuture<Void> {
        guard count > 0 else { return conn.eventLoop.future() }
        return conn.query(sql: batchInsertQuery(schema: schema))
    }
    
    public func batchInsert(inSchema schema: Schemable.Type? = nil, on conn: BridgeConnection) async throws {
        if count > 0 {
            try await conn.query(sql: batchInsertQuery(schema: schema?.schemaName ?? (Element.self as? Schemable.Type)?.schemaName))
        }
    }
    
    public func batchInsert(schema: String, on conn: BridgeConnection) async throws {
        if count > 0 {
            try await conn.query(sql: batchInsertQuery(schema: schema))
        }
    }
    
    private func batchInsertQuery(schema: String?) -> SwifQLable {
        var data: [String: [SwifQLable]] = [:]
        self.forEach { table in
            table.columns.forEach {
                let value = $0.property.inputValue?.swifQLable ?? SwifQL.default
                if var d = data[$0.name.label] {
                    d.append(value)
                    data[$0.name.label] = d
                } else {
                    data[$0.name.label] = [value]
                }
            }
        }
        let columns = data.keys.sorted(by: { $0 > $1 })
        var values: [[SwifQLable]] = []
        enumerated().forEach { i, _ in
            columns.enumerated().forEach { n, c in
                if let v = data[c]?[i] {
                    if values.count < i + 1 {
                        values.append([v])
                    } else {
                        values[i].append(v)
                    }
                }
            }
        }
        return SwifQL
            .insertInto(Path.Schema(schema).table(Element.tableName), fields: columns.map { Path.Column($0) })
            .values
            .values(array: values)
    }
}
