//
//  Bridgeable+Transaction.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import NIO
import Logging
import SwifQL

extension Bridgeable {
    public func transaction<T>(to db: DatabaseIdentifier,
                               on eventLoop: EventLoop,
                               _ closure: @escaping (Connection) -> EventLoopFuture<T>) -> EventLoopFuture<T> {
        connection(to: db, on: eventLoop) { conn in
            conn.query(raw: SwifQL.begin.semicolon.prepare().plain).transform(to: conn).flatMap { conn in
                closure(conn).flatMapError { error in
                    conn.query(raw: SwifQL.rollback.semicolon.prepare().plain).flatMapThrowing { _ in
                        throw error
                    }
                }.flatMap { v in
                    conn.query(raw: SwifQL.commit.semicolon.prepare().plain).transform(to: v)
                }
            }
        }
    }
    
    public func transaction<T>(to db: DatabaseIdentifier,
                               on eventLoop: EventLoop,
                               _ closure: @escaping (Connection) async throws -> T
    ) async throws -> T {
        try await connection(to: db, on: eventLoop) { conn in
            try await conn.query(raw: SwifQL.begin.semicolon.prepare().plain)
            do {
                let result = try await closure(conn)
                try await conn.query(raw: SwifQL.commit.semicolon.prepare().plain)
                return result
            } catch {
                try await conn.query(raw: SwifQL.rollback.semicolon.prepare().plain)
                throw error
            }
        }
    }
    
    public func shutdown() {
        pools.values.forEach { $0.shutdown() }
    }
}
