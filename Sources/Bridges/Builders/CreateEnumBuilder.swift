//
//  CreateEnumBuilder.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import SwifQL

public class CreateEnumBuilder<Enum: BridgesEnum>: SwifQLable where Enum.RawValue == String {
    public var parts: [SwifQLPart] {
        SwifQL
            .create
            .type((Enum.self as? Schemable.Type)?.schemaName ?? nil, Enum.name)
            .as(.enum)
            .values(values.count > 0 ? values : Enum.allCases.map { $0.rawValue })
            .semicolon
            .parts
    }
    
    var values: [Enum.RawValue] = []
    
    public init () {}
    
    public func add(_ values: Enum.RawValue...) -> Self {
        return self.add(values)
    }
    
    public func add(_ values: Enum...) -> Self {
        return self.add(values)
    }
    
    public func add(_ values: [Enum]) -> Self {
        self.values.append(contentsOf: values.map { $0.rawValue })
        return self
    }
    
    public func add(_ values: [Enum.RawValue]) -> Self {
        self.values.append(contentsOf: values)
        return self
    }
}
