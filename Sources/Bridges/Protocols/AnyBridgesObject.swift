//
//  AnyBridgesObject.swift
//  Bridges
//
//  Created by Mihael Isaev on 09.05.2020.
//

import Logging
import NIO

public protocol AnyBridgesObject {
    var logger: Logger { get }
    var bridges: Bridges { get }
    var eventLoop: EventLoop { get }
}
