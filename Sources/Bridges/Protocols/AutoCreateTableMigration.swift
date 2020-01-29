////
////  AutoCreateTableMigration.swift
////  Bridges
////
////  Created by Mihael Isaev on 27.01.2020.
////
//
//import NIO
//import SwifQL
//
//public protocol AutoCreateTableMigration: TableMigration {
//    static var columns: [NewColumn] { get }
//}
//
//extension AutoCreateTableMigration {
//    public static var columns: [NewColumn] {
//        Mirror(reflecting: Self.Table.init()).children.compactMap { child in
//            guard let child = child.value as? AnyColumn else { return nil }
//            let newColumn = NewColumn(child.name, child.type)
//            if let expression = child.default?.query {
//                newColumn.default(expression: expression)
//            }
//            child.constraints.forEach {
//                newColumn.constraint(expression: $0.query)
//            }
//            return newColumn
//        }
//    }
//    
//    public static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
//        let query = SwifQL.create.table.if.not.exists[any: Path.Table(Self.Table.name)].newColumns(columns)
//        return conn.query(raw: query.semicolon.prepare(conn.dialect).plain).transform(to: ())
//    }
//    
//    public static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
//        conn.query(raw: SwifQL.drop.table.if.exists[any: Path.Table(Self.Table.name)].prepare(conn.dialect).plain).transform(to: ())
//    }
//}
