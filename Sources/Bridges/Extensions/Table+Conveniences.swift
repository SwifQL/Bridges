//
//  Table+Conveniences.swift
//  Bridges
//
//  Created by Mihael Isaev on 09.05.2020.
//

import Logging
import NIO
import SwifQL

extension Table {
    fileprivate static func error(_ logger: Logger) {
        logger.error(.init(stringLiteral: "Query doesn't work with non-generic database identifier. Please initialize AnyDatabaseIdentifier as MySQL or Postgres explicitly."))
    }
    
    public static func all(on db: DatabaseIdentifier, on: AnyBridgesObject) -> EventLoopFuture<[Self]> {
        guard let db = db as? AnyDatabaseIdentifiable else {
            error(on.logger)
            return on.eventLoop.makeFailedFuture(BridgesError.nonGenericDatabaseIdentifier)
        }
        return db.all(Self.self, on: on)
    }
    
    public static func first(on db: DatabaseIdentifier, on: AnyBridgesObject) -> EventLoopFuture<Self?> {
        guard let db = db as? AnyDatabaseIdentifiable else {
            error(on.logger)
            return on.eventLoop.makeFailedFuture(BridgesError.nonGenericDatabaseIdentifier)
        }
        return db.first(Self.self, on: on)
    }
    
    public static func query(_ db: DatabaseIdentifier, on container: AnyBridgesObject) -> TableQuerySingle<Self> {
        .init(db: db, container: container)
    }
    
    public static func query(on conn: BridgeConnection) -> TableQueryOnConn<Self> {
        .init(conn)
    }
}

struct CountResult: Aliasable {
    @Alias("count")
    var count: Int64
}

public class TableQuerySingle<T: Table>: QueryBuilderable {
    let db: AnyDatabaseIdentifiable
    let container: AnyBridgesObject
    
    public var queryParts = QueryParts()
    
    private init (db: AnyDatabaseIdentifiable, container: AnyBridgesObject) {
        self.db = db
        self.container = container
    }
    
    init (db: DatabaseIdentifier, container: AnyBridgesObject) {
        guard let db = db as? AnyDatabaseIdentifiable else {
            T.error(container.logger)
            fatalError()
        }
        self.db = db
        self.container = container
    }
    
    public func copy() -> TableQuerySingle<T> {
        let copy = TableQuerySingle<T>(db: db, container: container)
        
        copy.queryParts = queryParts.copy()
        
        return copy
    }
    
    public func all() -> EventLoopFuture<[T]> {
        let query = SwifQL.select(T.table.*).from(T.table)
        return db.query(queryParts.appended(to: query), on: container)
            .flatMapThrowing { try $0.map { try $0.decode(model: T.self) } }
    }
    
    public func count() -> EventLoopFuture<Int64> {
        let query = SwifQL.select(Fn.count(T.table.*) => \CountResult.$count).from(T.table)
        return db.query(queryParts.appended(to: query), on: container)
            .flatMapThrowing { try $0.first?.decode(model: CountResult.self).count ?? 0 }
    }
    
    public func first() -> EventLoopFuture<T?> {
        let query = SwifQL.select(T.table.*).from(T.table)
        return db.query(queryParts.appended(to: query), on: container)
            .flatMapThrowing { try $0.first?.decode(model: T.self) }
    }
    
    public func delete() -> EventLoopFuture<Void> {
        let query = SwifQL.delete(from: T.table)
        return db.query(queryParts.appended(to: query), on: container).transform(to: ())
    }
}

public class TableQueryOnConn<T: Table>: QueryBuilderable {
    let conn: BridgeConnection
    
    public var queryParts = QueryParts()
    
    init (_ conn: BridgeConnection) {
        self.conn = conn
    }
    
    public func copy() -> TableQueryOnConn<T> {
        let copy = TableQueryOnConn<T>(conn)
        
        copy.queryParts = queryParts.copy()
        
        return copy
    }
    
    public func all() -> EventLoopFuture<[T]> {
        let query = SwifQL.select(T.table.*).from(T.table)
        return conn.query(sql: queryParts.appended(to: query), decoding: T.self)
    }
    
    public func count() -> EventLoopFuture<Int64> {
        let query = SwifQL.select(Fn.count(T.table.*) => \CountResult.$count).from(T.table)
        return conn.query(sql: queryParts.appended(to: query), decoding: CountResult.self).map { $0.first?.count ?? 0 }
    }
    
    public func first() -> EventLoopFuture<T?> {
        let query = SwifQL.select(T.table.*).from(T.table)
        return conn.query(sql: queryParts.appended(to: query), decoding: T.self).map { $0.first }
    }
    
    public func delete() -> EventLoopFuture<Void> {
        let query = SwifQL.delete(from: T.table)
        return conn.query(sql: queryParts.appended(to: query), decoding: T.self).transform(to: ())
    }
}
