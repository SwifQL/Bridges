//
//  Bridgeable.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import AsyncKit
import Logging
import NIO
import SwifQL

public protocol Bridgeable: AnyBridge {
    associatedtype Source: BridgesPoolSource
    associatedtype Database
    associatedtype Connection: BridgeConnection
    
    typealias GroupPool = EventLoopGroupConnectionPool<Source>
    typealias Pool = EventLoopConnectionPool<Source>
    
    static var dialect: SQLDialect { get }
    
    var pools: [String: GroupPool] { get set }
    
    var logger: Logger { get }
    var eventLoopGroup: EventLoopGroup { get }
    
    init (eventLoopGroup: EventLoopGroup, logger: Logger)
    
    func register(_ db: DatabaseIdentifier)
    
    func pool(_ db: DatabaseIdentifier, for eventLoop: EventLoop) -> Pool
    
    func db(_ db: DatabaseIdentifier, on eventLoop: EventLoop) -> Database
                
    func connection<T>(to db: DatabaseIdentifier,
                                  on eventLoop: EventLoop,
                                  _ closure: @escaping (Connection) -> EventLoopFuture<T>) -> EventLoopFuture<T>
    
    func transaction<T>(to db: DatabaseIdentifier,
                                  on eventLoop: EventLoop,
                                  _ closure: @escaping (Connection) -> EventLoopFuture<T>) -> EventLoopFuture<T>
    
    func shutdown()
    
    func migrations(_ db: DatabaseIdentifier) -> BridgeDatabaseMigrations<Self>
}

// MARK: Default implementation

extension Bridgeable {
    @discardableResult
    private func _register(_ db: DatabaseIdentifier) -> GroupPool {
        let pool = GroupPool(
            source: .init(db),
            maxConnectionsPerEventLoop: db.maxConnectionsPerEventLoop,
            logger: logger,
            on: eventLoopGroup
        )
        pools[db.key] = pool
        return pool
    }
    
    public func register(_ db: DatabaseIdentifier) {
        _register(db)
    }
    
    public func pool(_ db: DatabaseIdentifier, for eventLoop: EventLoop) -> Pool {
        let pool = pools[db.key] ?? _register(db)
        return pool.pool(for: eventLoop)
    }
    
    public func migrations(_ db: DatabaseIdentifier) -> BridgeDatabaseMigrations<Self> {
        .init(self, db: db)
    }
}
