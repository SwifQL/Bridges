//
//  AnyDatabaseIdentifiable.swift
//  Bridges
//
//  Created by Mihael Isaev on 09.05.2020.
//

import SwifQL
import NIO

public protocol AnyDatabaseIdentifiable {}
public protocol AnyMySQLDatabaseIdentifiable: AnyDatabaseIdentifiable {}
public protocol AnyPostgresDatabaseIdentifiable: AnyDatabaseIdentifiable {}

public protocol DatabaseIdentifiable {
    associatedtype B: Bridgeable
}
public protocol MySQLDatabaseIdentifiable: DatabaseIdentifiable, AnyMySQLDatabaseIdentifiable {}
public protocol PostgresDatabaseIdentifiable: DatabaseIdentifiable, AnyPostgresDatabaseIdentifiable {}
