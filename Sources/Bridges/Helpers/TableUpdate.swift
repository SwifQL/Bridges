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
    fileprivate func buildUpdateQuery(items: Columns, where: SwifQLable, returning: Bool) -> SwifQLable {
        let query = SwifQL
            .update(Self.table)
            .set[items: items.map { Path.Column($0.name) == $0.value }]
            .where(`where`)
        guard returning else { return query }
        return query.returning.asterisk
    }
    
    // MARK: Standalone
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @escaping () throws -> Void
    ) -> EventLoopFuture<Void> {
        container.eventLoop.future().flatMapThrowing {
            try preActions()
        }.flatMap {
            self.updateNonReturning(on: keyColumn, on: db, on: container)
        }
    }
    
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
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @escaping (Self) throws -> Void
    ) -> EventLoopFuture<Void> {
        container.eventLoop.future().flatMapThrowing {
            try preActions(self)
        }.flatMap {
            self.updateNonReturning(on: keyColumn, on: db, on: container)
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
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: () -> EventLoopFuture<T>
    ) -> EventLoopFuture<Void> {
        preActions().flatMap { _ in
            self.updateNonReturning(on: keyColumn, on: db, on: container)
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
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: (Self) -> EventLoopFuture<T>
    ) -> EventLoopFuture<Void> {
        preActions(self).flatMap { _ in
            self.updateNonReturning(on: keyColumn, on: db, on: container)
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
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Void> {
        guard let items = allColumns(excluding: keyColumn, logger: container.logger) else {
            return container.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        guard items.0.count > 0 else {
            container.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return container.eventLoop.makeSucceededVoidFuture()
        }
        return buildUpdateQuery(items: items.0, where: items.1 == items.2, returning: false)
            .execute(on: db, on: container)
            .transform(to: ())
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        guard let items = allColumns(excluding: keyColumn, logger: container.logger) else {
            return container.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        guard items.0.count > 0 else {
            container.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return container.eventLoop.makeSucceededFuture(self)
        }
        return buildUpdateQuery(items: items.0, where: items.1 == items.2, returning: true)
            .execute(on: db, on: container)
            .all(decoding: Self.self)
            .flatMapThrowing { rows in
                guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
                return row
            }
    }
    
    ///
    
    public func updateNonReturning(
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        where predicates: SwifQLable
    ) -> EventLoopFuture<Void> {
        let items = allColumns(logger: container.logger)
        guard items.count > 0 else {
            container.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return container.eventLoop.makeSucceededVoidFuture()
        }
        return buildUpdateQuery(items: items, where: predicates, returning: false)
            .execute(on: db, on: container)
            .transform(to: ())
    }
    
    public func update(
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        where predicates: SwifQLable
    ) -> EventLoopFuture<Self> {
        let items = allColumns(logger: container.logger)
        guard items.count > 0 else {
            container.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return container.eventLoop.makeSucceededFuture(self)
        }
        return buildUpdateQuery(items: items, where: predicates, returning: true)
            .execute(on: db, on: container)
            .all(decoding: Self.self)
            .flatMapThrowing { rows in
                guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
                return row
            }
    }
    
    // MARK: On connection
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: @escaping () throws -> Void
    ) -> EventLoopFuture<Void> {
        conn.eventLoop.future().flatMapThrowing {
            try preActions()
        }.flatMap {
            self.updateNonReturning(on: keyColumn, on: conn)
        }
    }
    
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
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: @escaping (Self) throws -> Void
    ) -> EventLoopFuture<Void> {
        conn.eventLoop.future().flatMapThrowing {
            try preActions(self)
        }.flatMap {
            self.updateNonReturning(on: keyColumn, on: conn)
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
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: () -> EventLoopFuture<T>
    ) -> EventLoopFuture<Void> {
        preActions().flatMap { _ in
            self.updateNonReturning(on: keyColumn, on: conn)
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
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: (Self) -> EventLoopFuture<T>
    ) -> EventLoopFuture<Void> {
        preActions(self).flatMap { _ in
            self.updateNonReturning(on: keyColumn, on: conn)
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
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Void> {
        guard let items = allColumns(excluding: keyColumn, logger: conn.logger) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        guard items.0.count > 0 else {
            conn.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return conn.eventLoop.makeSucceededVoidFuture()
        }
        let query = buildUpdateQuery(items: items.0, where: items.1 == items.2, returning: false)
        return conn.query(sql: query)
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection
    ) -> EventLoopFuture<Self> {
        guard let items = allColumns(excluding: keyColumn, logger: conn.logger) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        guard items.0.count > 0 else {
            conn.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return conn.eventLoop.makeSucceededFuture(self)
        }
        let query = buildUpdateQuery(items: items.0, where: items.1 == items.2, returning: true)
        return conn.query(sql: query, decoding: Self.self).flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
    
    ///
    
    public func update(on conn: BridgeConnection, where predicates: SwifQLable) -> EventLoopFuture<Void> {
        conn.query(sql: buildUpdateQuery(items: allColumns(logger: conn.logger), where: predicates, returning: false))
    }
    
    /// ASYNC
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @escaping @Sendable () async throws -> Void
    ) async throws {
        try await preActions()
        try await updateNonReturning(on: keyColumn, on: db, on: container)
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @escaping @Sendable () async throws -> Void
    ) async throws -> Self {
        try await preActions()
        return try await update(on: keyColumn, on: db, on: container)
    }
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @escaping @Sendable (Self) async throws -> Void
    ) async throws {
        try await preActions(self)
        try await updateNonReturning(on: keyColumn, on: db, on: container)
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @escaping @Sendable (Self) async throws -> Void
    ) async throws -> Self {
        try await preActions(self)
        return try await update(on: keyColumn, on: db, on: container)
    }
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @Sendable () async throws -> T
    ) async throws {
        _ = try await preActions()
        try await updateNonReturning(on: keyColumn, on: db, on: container)
    }
    
    public func update<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @Sendable () async throws -> T
    ) async throws -> Self {
        _ = try await preActions()
        return try await update(on: keyColumn, on: db, on: container)
    }
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @Sendable (Self) async throws -> T
    ) async throws {
        _ = try await preActions(self)
        try await updateNonReturning(on: keyColumn, on: db, on: container)
    }
    
    public func update<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        preActions: @Sendable (Self) async throws -> T
    ) async throws -> Self {
        _ = try await preActions(self)
        return try await update(on: keyColumn, on: db, on: container)
    }
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) async throws {
        guard let items = allColumns(excluding: keyColumn, logger: container.logger) else {
            throw BridgesError.valueIsNilInKeyColumnUpdateIsImpossible
        }
        guard items.0.count > 0 else {
            container.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return
        }
        _ = try await buildUpdateQuery(items: items.0, where: items.1 == items.2, returning: false)
            .execute(on: db, on: container)
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) async throws -> Self {
        guard let items = allColumns(excluding: keyColumn, logger: container.logger) else {
            throw BridgesError.valueIsNilInKeyColumnUpdateIsImpossible
        }
        guard items.0.count > 0 else {
            container.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return self
        }
        guard let first = try await buildUpdateQuery(items: items.0, where: items.1 == items.2, returning: true)
            .execute(on: db, on: container)
            .all(decoding: Self.self).first
        else {
            throw BridgesError.failedToDecodeWithReturning
        }
        return first
    }
    
    ///
    
    public func updateNonReturning(
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        where predicates: SwifQLable
    ) async throws {
        let items = allColumns(logger: container.logger)
        guard items.count > 0 else {
            container.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return
        }
        _ = try await buildUpdateQuery(items: items, where: predicates, returning: false)
            .execute(on: db, on: container)
    }
    
    public func update(
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject,
        where predicates: SwifQLable
    ) async throws -> Self {
        let items = allColumns(logger: container.logger)
        guard items.count > 0 else {
            container.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return self
        }
        guard let first = try await buildUpdateQuery(items: items, where: predicates, returning: true)
            .execute(on: db, on: container)
            .all(decoding: Self.self).first
        else {
            throw BridgesError.failedToDecodeWithReturning
        }
        return first
    }
    
    // MARK: On connection
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: @escaping () throws -> Void
    ) async throws -> EventLoopFuture<Void> {
        conn.eventLoop.future().flatMapThrowing {
            try preActions()
        }.flatMap {
            self.updateNonReturning(on: keyColumn, on: conn)
        }
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: @escaping () throws -> Void
    ) async throws -> EventLoopFuture<Self> {
        conn.eventLoop.future().flatMapThrowing {
            try preActions()
        }.flatMap {
            self.update(on: keyColumn, on: conn)
        }
    }
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: @escaping (Self) throws -> Void
    ) async throws -> EventLoopFuture<Void> {
        conn.eventLoop.future().flatMapThrowing {
            try preActions(self)
        }.flatMap {
            self.updateNonReturning(on: keyColumn, on: conn)
        }
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: @escaping (Self) throws -> Void
    ) async throws -> EventLoopFuture<Self> {
        conn.eventLoop.future().flatMapThrowing {
            try preActions(self)
        }.flatMap {
            self.update(on: keyColumn, on: conn)
        }
    }
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: () -> EventLoopFuture<T>
    ) async throws -> EventLoopFuture<Void> {
        preActions().flatMap { _ in
            self.updateNonReturning(on: keyColumn, on: conn)
        }
    }
    
    public func update<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: () -> EventLoopFuture<T>
    ) async throws -> EventLoopFuture<Self> {
        preActions().flatMap { _ in
            self.update(on: keyColumn, on: conn)
        }
    }
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: (Self) -> EventLoopFuture<T>
    ) async throws -> EventLoopFuture<Void> {
        preActions(self).flatMap { _ in
            self.updateNonReturning(on: keyColumn, on: conn)
        }
    }
    
    public func update<Column: ColumnRepresentable, T>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection,
        preActions: (Self) -> EventLoopFuture<T>
    ) async throws -> EventLoopFuture<Self> {
        preActions(self).flatMap { _ in
            self.update(on: keyColumn, on: conn)
        }
    }
    
    ///
    
    public func updateNonReturning<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection
    ) async throws -> EventLoopFuture<Void> {
        guard let items = allColumns(excluding: keyColumn, logger: conn.logger) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        guard items.0.count > 0 else {
            conn.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return conn.eventLoop.makeSucceededVoidFuture()
        }
        let query = buildUpdateQuery(items: items.0, where: items.1 == items.2, returning: false)
        return conn.query(sql: query)
    }
    
    public func update<Column: ColumnRepresentable>(
        on keyColumn: KeyPath<Self, Column>,
        on conn: BridgeConnection
    ) async throws -> EventLoopFuture<Self> {
        guard let items = allColumns(excluding: keyColumn, logger: conn.logger) else {
            return conn.eventLoop.makeFailedFuture(BridgesError.valueIsNilInKeyColumnUpdateIsImpossible)
        }
        guard items.0.count > 0 else {
            conn.logger.debug("\(Self.tableName) update has been skipped cause nothing to update")
            return conn.eventLoop.makeSucceededFuture(self)
        }
        let query = buildUpdateQuery(items: items.0, where: items.1 == items.2, returning: true)
        return conn.query(sql: query, decoding: Self.self).flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
    
    ///
    
    public func update(on conn: BridgeConnection, where predicates: SwifQLable) async throws -> EventLoopFuture<Void> {
        conn.query(sql: buildUpdateQuery(items: allColumns(logger: conn.logger), where: predicates, returning: false))
    }
    
}

fileprivate func error(_ logger: Logger) {
    logger.error(.init(stringLiteral: "Query doesn't work with non-generic database identifier. Please initialize AnyDatabaseIdentifier as MySQL or Postgres explicitly."))
}
