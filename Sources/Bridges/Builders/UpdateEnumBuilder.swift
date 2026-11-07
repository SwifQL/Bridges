//
//  UpdateEnumBuilder.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import SQL

public class UpdateEnumBuilder<Enum: BridgesEnum> where Enum.RawValue == String {
    public var actions: [SQLable] = []
    
    public init () {}
    
    public func add(_ value: String) -> Self {
        actions.append(SQL.alter.type((Enum.self as? Schemable.Type)?.schemaName ?? nil, Enum.name).add.value[any: value].semicolon)
        return self
    }
    
    public func add(_ value: String, before v: String) -> Self {
        actions.append(SQL.alter.type((Enum.self as? Schemable.Type)?.schemaName ?? nil, Enum.name).add.value[any: value].before[any: v].semicolon)
        return self
    }
    
    public func add(_ value: String, after v: String) -> Self {
        actions.append(SQL.alter.type((Enum.self as? Schemable.Type)?.schemaName ?? nil, Enum.name).add.value[any: value].after[any: v].semicolon)
        return self
    }
    
    public func execute(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        actions.map { action in
            { action.execute(on: conn) }
        }.flatten(on: conn.eventLoop)
    }
}
