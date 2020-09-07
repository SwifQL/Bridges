//
//  UpdateEnumBuilder.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import SwifQL

public class UpdateEnumBuilder<Enum: BridgesEnum> where Enum.RawValue == String {
    public var actions: [SwifQLable] = []
    
    public init () {}
    
    public func add(_ value: String) -> Self {
        actions.append(SwifQL.alter.type(Enum.schema, Enum.name).add.value[any: value].semicolon)
        return self
    }
    
    public func add(_ value: String, before v: String) -> Self {
        actions.append(SwifQL.alter.type(Enum.schema, Enum.name).add.value[any: value].before[any: v].semicolon)
        return self
    }
    
    public func add(_ value: String, after v: String) -> Self {
        actions.append(SwifQL.alter.type(Enum.schema, Enum.name).add.value[any: value].after[any: v].semicolon)
        return self
    }
    
    public func execute(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        actions.map { action in
            { action.execute(on: conn) }
        }.flatten(on: conn.eventLoop)
    }
}
