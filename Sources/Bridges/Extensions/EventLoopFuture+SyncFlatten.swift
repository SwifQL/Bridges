//
//  EventLoopFuture+SyncFlatten.swift
//  Bridges
//
//  Created by Mihael Isaev on 29.01.2020.
//

import Foundation

public extension Array where Element == (() -> EventLoopFuture<Void>) {
    func flatten(on eventLoop: EventLoop) -> EventLoopFuture<Void> {
        let promise = eventLoop.makePromise(of: Void.self)
        
        var iterator = self.makeIterator()
        func handle(_ future: () -> EventLoopFuture<Void>) {
            future().whenComplete { res in
                switch res {
                case .success:
                    if let next = iterator.next() {
                        handle(next)
                    } else {
                        promise.succeed(())
                    }
                case .failure(let error):
                    promise.fail(error)
                }
            }
        }
        
        if let first = iterator.next() {
            handle(first)
        } else {
            promise.succeed(())
        }
        
        return promise.futureResult
    }
}

public extension Array where Element == (() async throws -> Void) {
    
    func flatten() async throws {
        var iterator = self.makeIterator()
        while let item = iterator.next() {
            try await item()
        }
    }
}
