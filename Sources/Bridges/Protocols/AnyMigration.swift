//
//  AnyMigration.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import NIO

public protocol AnyMigration {
    static var name: String { get }
    
    static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void>
    static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void>
}

extension AnyMigration {
    public static var name: String { String(describing: Self.self) }
}
