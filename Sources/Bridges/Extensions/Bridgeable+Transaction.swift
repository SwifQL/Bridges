//
//  Bridgeable+Transaction.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import NIO
import Logging
import SQL

extension Bridgeable {
    public func transaction<T>(to db: DatabaseIdentifier,
                                            on eventLoop: EventLoop,
                                            _ closure: @escaping (Connection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        connection(to: db, on: eventLoop) { conn in
            conn.query(raw: SQL.begin.semicolon.prepare().plain).transform(to: conn).flatMap { conn in
                closure(conn).flatMapError { error in
                    conn.query(raw: SQL.rollback.semicolon.prepare().plain).flatMapThrowing { _ in
                        throw error
                    }
                }.flatMap { v in
                    conn.query(raw: SQL.commit.semicolon.prepare().plain).transform(to: v)
                }
            }
        }
    }
    
    public func shutdown() {
        pools.values.forEach { $0.shutdown() }
    }
}
