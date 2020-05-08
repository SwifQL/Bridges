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
    private static func error(_ logger: Logger) {
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
}
