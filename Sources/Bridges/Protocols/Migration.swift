//
//  Migration.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import NIO

public protocol Migration: AnyMigration {
    associatedtype Connection: BridgeConnection
    
    static func prepare(on conn: Connection) -> EventLoopFuture<Void>
    static func revert(on conn: Connection) -> EventLoopFuture<Void>
    
    static func prepare(on conn: Connection) async throws
    static func revert(on conn: Connection) async throws
}

extension Migration {
    public static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        prepare(on: conn as! Connection)
    }
    
    public static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        revert(on: conn as! Connection)
    }
    
    public static func prepare(on conn: BridgeConnection) async throws {
        try await prepare(on: conn as! Connection)
    }
    
    public static func revert(on conn: BridgeConnection) async throws {
        try await revert(on: conn as! Connection)
    }
}
