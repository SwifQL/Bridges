//
//  SchemaMigration.swift
//  Bridges
//
//  Created by Mihael Isaev on 12.04.2020.
//

import SwifQL

public protocol SchemaMigration: AnyMigration {
    associatedtype Schema: Schemable
}

extension SchemaMigration {
    public static var createBuilder: CreateSchemaBuilder<Schema> { .init() }
    public static var renameBuilder: UpdateSchemaRenameBuilder<Schema> { .init() }
    public static var changeOwnerBuilder: UpdateSchemaChangeOwner<Schema> { .init() }
    public static var dropBuilder: DropSchemaBuilder<Schema> { .init() }
}
