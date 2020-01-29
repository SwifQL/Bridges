//
//  EnumMigration.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import SwifQL

public protocol EnumMigration: AnyMigration {
    associatedtype Enum: BridgesEnum
}

extension EnumMigration where Enum.RawValue == String {
    public static var createBuilder: CreateEnumBuilder<Enum> { .init() }
    public static var updateBuilder: UpdateEnumBuilder<Enum> { .init() }
}

extension EnumMigration {
    public static var dropBuilder: DropEnumBuilder<Enum> { .init() }
}
