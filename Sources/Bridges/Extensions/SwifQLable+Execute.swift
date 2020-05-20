//
//  SwifQLable+Execute.swift
//  Bridges
//
//  Created by Mihael Isaev on 20.05.2020.
//

import Logging
import NIO
import SwifQL

public struct BridgesExecutedResult {
    let db: AnyDatabaseIdentifiable
    let container: AnyBridgesObject
    
    public let rows: [BridgesRow]
    
    init (db: AnyDatabaseIdentifiable, container: AnyBridgesObject, rows: [BridgesRow]) {
        self.db = db
        self.container = container
        self.rows = rows
    }
}

extension EventLoopFuture where Value == BridgesExecutedResult {
    public func all<T>() -> EventLoopFuture<[T]> where T: Decodable {
        all(decoding: T.self)
    }
    
    
    public func all<T>(decoding: T.Type) -> EventLoopFuture<[T]> where T: Decodable {
        flatMapThrowing {
            try $0.rows.map { try $0.decode(model: T.self) }
        }
    }
    
    public func first<T>() -> EventLoopFuture<T?> where T: Table {
        first(decoding: T.self)
    }
    
    public func first<T>(decoding: T.Type) -> EventLoopFuture<T?> where T: Decodable {
        flatMapThrowing {
            try $0.rows.first?.decode(model: T.self)
        }
    }
    
    public func count() -> EventLoopFuture<Int64> {
        map { .init($0.rows.count) }
    }
}

extension SwifQLable {
    public func execute(_ db: DatabaseIdentifier, on container: AnyBridgesObject) -> EventLoopFuture<BridgesExecutedResult> {
        guard let db = db as? AnyDatabaseIdentifiable else {
            error(container.logger)
            return container.eventLoop.makeFailedFuture(BridgesError.nonGenericDatabaseIdentifier)
        }
        return db.query(self, on: container).map { .init(db: db, container: container, rows: $0) }
    }
}

fileprivate func error(_ logger: Logger) {
    logger.error(.init(stringLiteral: "Query doesn't work with non-generic database identifier. Please initialize AnyDatabaseIdentifier as MySQL or Postgres explicitly."))
}
