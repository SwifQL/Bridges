//
//  Connection.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import NIO
import Logging
import SwifQL

public protocol BridgeConnection {
    var eventLoop: EventLoop { get }
    var logger: Logger { get }
    var isClosed: Bool { get }
    var dialect: SQLDialect { get }
    
    func query(raw: String) -> EventLoopFuture<Void>
    func query<V: Decodable>(raw: String, decoding type: V.Type) -> EventLoopFuture<[V]>
}
