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
            let value: SwifQLable
            if let v = $0.1.inputValue as? SwifQLable {
                value = v
            } else if let v = $0.1.inputValue as? Bool {
                value = SwifQLBool(v)
            } else {
                return nil
            }
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

// MARK: Batch Insert

extension Array where Element: Table {
    public func batchInsert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        guard count > 0 else { return conn.eventLoop.future() }
        return conn.query(sql: batchInsertQuery)
    }
    
//    public func batchInsertReturning(on conn: BridgeConnection) -> EventLoopFuture<[Element]> {
//        guard count > 0 else { return conn.eventLoop.future([]) }
//        return conn.query(sql: batchInsertQuery, decoding: Element.self)
//    }
    
    private var batchInsertQuery: SwifQLable {
        var data: [String: [SwifQLable]] = [:]
        self.forEach { table in
            table.columns.forEach { column, value in
                let value: SwifQLable = (value.inputValue as? SwifQLable) ?? SwifQL.default
                if var d = data[column] {
                    d.append(value)
                    data[column] = d
                } else {
                    data[column] = [value]
                }
            }
        }
        let columns = data.keys.sorted(by: { $0 > $1 })
        var values: [[SwifQLable]] = []
        enumerated().forEach { i, _ in
            columns.enumerated().forEach { n, c in
                if let v = data[c]?[i] {
                    if values.count < i + 1 {
                        values.append([v])
                    } else {
                        values[i].append(v)
                    }
                }
            }
        }
        return SwifQL
            .insertInto(Element.tableName, fields: columns.map { Path.Column($0) })
            .values
            .values(array: values)
    }
}
