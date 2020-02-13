//
//  DatabaseHost.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import NIOSSL

public struct DatabaseHost {
    public let address: () throws -> SocketAddress
    public let username: String
    public let password: String?
    public let tlsConfiguration: TLSConfiguration?

    public init (address: @escaping () throws -> SocketAddress, username: String, password: String?, tlsConfiguration: TLSConfiguration? = nil) {
        self.address = address
        self.username = username
        self.password = password
        self.tlsConfiguration = tlsConfiguration
    }
    
    public init (hostname: String, port: Int, username: String, password: String?, tlsConfiguration: TLSConfiguration? = nil) {
        self.address = {
            try SocketAddress.makeAddressResolvingHost(hostname, port: port)
        }
        self.username = username
        self.password = password
        self.tlsConfiguration = tlsConfiguration
    }
}
