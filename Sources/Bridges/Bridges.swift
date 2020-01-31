//
//  Bridges.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import Logging
import NIO

open class Bridges {
    var bridges: [String: AnyBridge] = [:]
    
    public let eventLoopGroup: EventLoopGroup
    public var logger: Logger
    
    public init(eventLoopGroup: EventLoopGroup, logger: Logger) {
        self.eventLoopGroup = eventLoopGroup
        self.logger = logger
    }
    
    public func bridge<B: AnyBridge>(to type: B.Type) -> B {
        let bridge = bridges[B.name] ?? B.create(eventLoopGroup: eventLoopGroup, logger: logger)
        if bridges[B.name] == nil { bridges[B.name]  = bridge }
        guard let castedBridge = bridge as? B else {
            fatalError("Unable to cast bridge to `\(B.name)`")
        }
        return castedBridge
    }
}

extension Table {
    public static func key<Column>(for column: KeyPath<Self, Column>) -> String where Column: ColumnRepresentable {
        Self.init()[keyPath: column].column.name
    }
}

import SwifQL

extension SwifQLable {
    @discardableResult
    public func execute(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        conn.query(raw: prepare(conn.dialect).plain).transform(to: ())
    }
}

extension KeyPath: SwifQLable, CustomStringConvertible, Keypathable where Root: Table, Value: ColumnRepresentable {
    public var paths: [String] {
        [Root.key(for: self)]
    }
    
    public var shortPath: String {
        Root.key(for: self)
    }
    
    public var lastPath: String {
        Root.key(for: self)
    }
    
    public func fullPath(table: String) -> String {
        Root.tableName
    }
    
    public var parts: [SwifQLPart] { Path.Table(Root.tableName).column(Root.key(for: self)).parts }
}

public protocol SQLRow {
    var allColumns: [String] { get }
    func contains(column: String) -> Bool
    func decodeNil(column: String) throws -> Bool
    func decode<D>(column: String, as type: D.Type) throws -> D
        where D: Decodable
}

extension SQLRow {
    public func decode<D>(model type: D.Type, prefix: String? = nil) throws -> D
        where D: Decodable
    {
        try SQLRowDecoder().decode(D.self, from: self, prefix: prefix)
    }
}

struct SQLRowDecoder {
    func decode<T>(_ type: T.Type, from row: SQLRow, prefix: String? = nil) throws -> T
        where T: Decodable
    {
        return try T.init(from: _Decoder(prefix: prefix, row: row))
    }

    enum _Error: Error {
        case nesting
        case unkeyedContainer
        case singleValueContainer
    }

    struct _Decoder: Decoder {
        let prefix: String?
        let row: SQLRow
        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey : Any] {
            [:]
        }

        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
            where Key: CodingKey
        {
            .init(_KeyedDecoder(prefix: self.prefix, row: self.row, codingPath: self.codingPath))
        }

        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw _Error.unkeyedContainer
        }

        func singleValueContainer() throws -> SingleValueDecodingContainer {
            throw _Error.singleValueContainer
        }
    }

    struct _KeyedDecoder<Key>: KeyedDecodingContainerProtocol
        where Key: CodingKey
    {
        let prefix: String?
        let row: SQLRow
        var codingPath: [CodingKey] = []
        var allKeys: [Key] {
            self.row.allColumns.compactMap {
                Key.init(stringValue: $0)
            }
        }

        func column(for key: Key) -> String {
            if let prefix = self.prefix {
                return prefix + key.stringValue
            } else {
                return key.stringValue
            }
        }

        func contains(_ key: Key) -> Bool {
            self.row.contains(column: self.column(for: key))
        }

        func decodeNil(forKey key: Key) throws -> Bool {
            try self.row.decodeNil(column: self.column(for: key))
        }

        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T
            where T : Decodable
        {
            try self.row.decode(column: self.column(for: key), as: T.self)
        }

        func nestedContainer<NestedKey>(
            keyedBy type: NestedKey.Type,
            forKey key: Key
        ) throws -> KeyedDecodingContainer<NestedKey>
            where NestedKey : CodingKey
        {
            throw _Error.nesting
        }

        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
            throw _Error.nesting
        }

        func superDecoder() throws -> Decoder {
            _Decoder(prefix: self.prefix, row: self.row, codingPath: self.codingPath)
        }

        func superDecoder(forKey key: Key) throws -> Decoder {
            throw _Error.nesting
        }
    }
}
