//
//  TableCreate.swift
//  Bridges
//
//  Created by Mihael Isaev on 31.01.2020.
//

import NIO
import SwifQL

extension Table {
    public func insert(on conn: BridgeConnection) -> EventLoopFuture<Self> {
        let items: [(String, SwifQLable)] = columns.compactMap {
            guard let value = $0.1.inputValue as? SwifQLable else { return nil }
            return ($0.0, value)
        }
        let query = SwifQL
        .insertInto(Self.tableName, fields: items.map { Path.Column($0.0) })
        .values
        .values(items.map { $0.1 })
        .returning
        .asterisk
        return conn.query(sql: query, decoding: Self.self).flatMapThrowing { rows in
            guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
            return row
        }
    }
}
