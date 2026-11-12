//
//  Enum.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import SQL

public protocol BridgesEnum: SQLEnum {
    associatedtype Enum = Self
}

extension BridgesEnum {
    public typealias Enum = Self
}
