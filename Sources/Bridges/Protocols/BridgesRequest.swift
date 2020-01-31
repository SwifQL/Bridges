//
//  BridgesRequest.swift
//  Bridges
//
//  Created by Mihael Isaev on 30.01.2020.
//

public protocol BridgesRequest {
    var bridgesApplication: BridgesApplication { get }
    var eventLoop: EventLoop { get }
}
