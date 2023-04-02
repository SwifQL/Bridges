//
//  AnyMigration.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import NIO

public protocol AnyMigration {
    static var name: String { get }
    static var migrationName: String { get }
    
    static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void>
    static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void>
    
    static func prepare(on conn: BridgeConnection) async throws
    static func revert(on conn: BridgeConnection) async throws
}

extension AnyMigration {
    public static var name: String { String(describing: Self.self) }
    public static var migrationName: String { name }
}
