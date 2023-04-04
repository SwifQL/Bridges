//
//  TableMigration.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import SwifQL

public protocol TableMigration: AnyMigration {
    associatedtype Table: BridgeTable
}

extension TableMigration {
    public static var createBuilder: CreateTableBuilder<Table> { .init() }
    public static var updateBuilder: UpdateTableBuilder<Table> { .init() }
    public static var dropBuilder: DropTableBuilder<Table> { .init() }
    
    static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        conn.eventLoop.future()
    }
    static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        conn.eventLoop.future()
    }
}
