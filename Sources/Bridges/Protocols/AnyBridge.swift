//
//  AnyBridge.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import NIO
import Logging

public protocol AnyBridge: class {
    static var name: String { get }
    
    static func create(eventLoopGroup: EventLoopGroup, logger: Logger) -> AnyBridge
    
    var logger: Logger { get }
}

extension AnyBridge {
    public static var name: String { String(describing: Self.self) }
}
