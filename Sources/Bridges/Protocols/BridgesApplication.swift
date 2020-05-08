//
//  BridgesApplication.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import Logging

public protocol BridgesApplication: AnyBridgesObject {
    var logger: Logger { get }
    var bridges: Bridges { get }
    var eventLoopGroup: EventLoopGroup { get }
}

/// See: `AnyBridgesObject`
extension BridgesApplication {
    public var eventLoop: EventLoop { eventLoopGroup.next() }
}
