//
//  DatabaseHost.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import NIOSSL

public struct DatabaseHost {
    public let hostname, username: String
    public let password: String?
    public let port: Int
    public let tlsConfiguration: TLSConfiguration?

    public init (hostname: String, username: String, password: String?, port: Int, tlsConfiguration: TLSConfiguration? = nil) {
        self.hostname = hostname
        self.username = username
        self.password = password
        self.port = port
        self.tlsConfiguration = tlsConfiguration
    }
}
