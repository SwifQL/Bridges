//
//  BridgesRow.swift
//  Bridges
//
//  Created by Mihael Isaev on 18.05.2020.
//

import Foundation

public protocol BridgesRow {
    func decode<D>(model type: D.Type) throws -> D where D: Decodable
    func decode<D>(model type: D.Type, prefix: String?) throws -> D where D: Decodable
}

extension BridgesRow {
    public func decode<D>(model type: D.Type) throws -> D where D : Decodable {
        try decode(model: type, prefix: nil)
    }
}

public protocol BridgesRows {
    var rows: [BridgesRow] { get }
}

extension BridgesRows {
    public func first<R>(as type: R.Type) throws -> R? where R: Decodable {
        try rows.first?.decode(model: type)
    }
    
    public func all<R>(as type: R.Type) throws -> [R] where R: Decodable {
        try rows.map { try $0.decode(model: type) }
    }
}

extension EventLoopFuture where Value: BridgesRows {
    public func first<R>(decoding type: R.Type) -> EventLoopFuture<R?> where R: Decodable {
        flatMapThrowing { try $0.first(as: type) }
    }
    
    public func all<R>(decoding type: R.Type) -> EventLoopFuture<[R]> where R: Decodable {
        flatMapThrowing { try $0.all(as: type) }
    }
    
    public func first<R>(decoding type: R.Type) async throws -> R? where R: Decodable {
        try await get().first(as: type)
    }
    
    public func all<R>(decoding type: R.Type) async throws -> [R] where R: Decodable {
        try await get().all(as: type)
    }
}

extension Array: BridgesRows where Element: BridgesRow {
    public var rows: [BridgesRow] { self }
}
