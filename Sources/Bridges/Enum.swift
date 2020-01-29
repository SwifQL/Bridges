//
//  Enum.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import SwifQL

public protocol BridgesEnum: SwifQLEnum {
    associatedtype Enum = Self
}

extension BridgesEnum {
    public typealias Enum = Self
    
    public static var name: String { String(describing: Self.self).lowercased() }
}
