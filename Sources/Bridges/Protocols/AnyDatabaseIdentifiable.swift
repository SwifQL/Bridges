//
//  AnyDatabaseIdentifiable.swift
//  Bridges
//
//  Created by Mihael Isaev on 09.05.2020.
//

import SQL
import NIO

public protocol AnyDatabaseIdentifiable {
    func all<T>(_ table: T.Type, on bridges: AnyBridgesObject) -> EventLoopFuture<[T]> where T: Table
    func first<T>(_ table: T.Type, on bridges: AnyBridgesObject) -> EventLoopFuture<T?> where T: Table
    func query(_ query: SQLable, on bridges: AnyBridgesObject) -> EventLoopFuture<[BridgesRow]>
}
public protocol AnyMySQLDatabaseIdentifiable: AnyDatabaseIdentifiable {}
public protocol AnyPostgresDatabaseIdentifiable: AnyDatabaseIdentifiable {}

public protocol DatabaseIdentifiable {
    associatedtype B: Bridgeable
}
public protocol MySQLDatabaseIdentifiable: DatabaseIdentifiable, AnyMySQLDatabaseIdentifiable {}
public protocol PostgresDatabaseIdentifiable: DatabaseIdentifiable, AnyPostgresDatabaseIdentifiable {}
