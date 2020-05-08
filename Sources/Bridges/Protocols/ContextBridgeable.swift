//
//  ContextBridgeable.swift
//  Bridges
//
//  Created by Mihael Isaev on 09.05.2020.
//

public protocol ContextBridgeable {
    associatedtype B: Bridgeable
    
    var context: BridgeWithContext<B> { get }
}
