//
//  DropEnumBuilder.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import SwifQL

public class DropEnumBuilder<Enum: BridgesEnum>: SwifQLable {
    public var parts: [SwifQLPart] {
        SwifQL.drop.type(Enum.name).semicolon.parts
    }
    
    public init () {}
}
