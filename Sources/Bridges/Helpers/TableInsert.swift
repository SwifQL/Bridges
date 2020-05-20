//
//  TableCreate.swift
//  Bridges
//
//  Created by Mihael Isaev on 31.01.2020.
//

import NIO
import SwifQL

extension Table {
    fileprivate func buildInsertQuery(items: Columns) -> SwifQLable {
        SwifQL
            .insertInto(Self.tableName, fields: items.map { Path.Column($0.0) })
            .values
            .values(items.map { $0.1 })
            .returning
            .asterisk
    }
    
    // MARK: Standalone
    
    public func insert(
        on db: DatabaseIdentifier,
        on container: AnyBridgesObject
    ) -> EventLoopFuture<Self> {
        buildInsertQuery(items: allColumns())
            .execute(on: db, on: container)
            .all(decoding: Self.self)
            .flatMapThrowing { rows in
                guard let row = rows.first else { throw BridgesError.failedToDecodeWithReturning }
                return row
            }
    }
    
    // MARK: On connection
    
    public func insert(on conn: BridgeConnection) -> EventLoopFuture<Self> {
        let query = buildInsertQuery(items: allColumns())
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
            table.columns.forEach {
                let value: SwifQLable = ($0.property.inputValue as? SwifQLable) ?? SwifQL.default
                if var d = data[$0.name.label] {
                    d.append(value)
                    data[$0.name.label] = d
                } else {
                    data[$0.name.label] = [value]
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
