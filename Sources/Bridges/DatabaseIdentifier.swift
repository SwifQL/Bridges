//
//  DatabaseIdentifier.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation

open class DatabaseIdentifier {
    public let name: String?
    public let host: DatabaseHost
    public let maxConnectionsPerEventLoop: Int
    
    public var key: String {
        name ?? "global"
    }
    
    public init (name: String? = nil, host: DatabaseHost, maxConnectionsPerEventLoop: Int = 1) {
        self.name = name
        self.host = host
        self.maxConnectionsPerEventLoop = maxConnectionsPerEventLoop
    }
}
