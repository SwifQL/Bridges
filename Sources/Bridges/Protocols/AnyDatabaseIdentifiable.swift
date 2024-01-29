//
//  AnyDatabaseIdentifiable.swift
//  Bridges
//
//  Created by Mihael Isaev on 09.05.2020.
//

import SwifQL
import NIO

public protocol AnyDatabaseIdentifiable {
    func all<T>(_ table: T.Type, on bridges: AnyBridgesObject) -> EventLoopFuture<[T]> where T: Table
    func first<T>(_ table: T.Type, on bridges: AnyBridgesObject) -> EventLoopFuture<T?> where T: Table
    func query(_ query: SwifQLable, on bridges: AnyBridgesObject) -> EventLoopFuture<[BridgesRow]>
    
    func all<T>(_ table: T.Type, on bridges: AnyBridgesObject) async throws -> [T] where T: Table
    func first<T>(_ table: T.Type, on bridges: AnyBridgesObject) async throws -> T? where T: Table
    func query(_ query: SwifQLable, on bridges: AnyBridgesObject) async throws -> [BridgesRow]
}
public protocol AnyMySQLDatabaseIdentifiable: AnyDatabaseIdentifiable {}
public protocol AnyPostgresDatabaseIdentifiable: AnyDatabaseIdentifiable {}

public protocol DatabaseIdentifiable {
    associatedtype B: Bridgeable
}
public protocol MySQLDatabaseIdentifiable: DatabaseIdentifiable, AnyMySQLDatabaseIdentifiable {}
public protocol PostgresDatabaseIdentifiable: DatabaseIdentifiable, AnyPostgresDatabaseIdentifiable {}
