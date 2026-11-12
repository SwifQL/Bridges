//
//  DropEnumBuilder.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import SQL

public class DropEnumBuilder<Enum: BridgesEnum>: SQLable {
    public var parts: [SQLPart] {
        SQL.drop.type((Enum.self as? Schemable.Type)?.schemaName ?? nil, Enum.name).semicolon.parts
    }
    
    public init () {}
}
