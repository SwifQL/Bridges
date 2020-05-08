//
//  BridgesRequest.swift
//  Bridges
//
//  Created by Mihael Isaev on 30.01.2020.
//

import Logging
import NIO

public protocol BridgesRequest: AnyBridgesObject {
    var bridgesApplication: BridgesApplication { get }
    var eventLoop: EventLoop { get }
}

/// See: `AnyBridgesObject`
extension BridgesRequest {
    public var logger: Logger { bridgesApplication.logger }
    public var bridges: Bridges { bridgesApplication.bridges }
}
