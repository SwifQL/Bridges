//
//  File.swift
//  
//
//  Created by Oleh Hudeichuk on 02.04.2023.
//

import Foundation

public extension Array {
    
    func map<T>(_ handler: @Sendable @escaping (Element) async throws -> T) async throws -> [T] {
        try await Task {
            var result: [T] = .init()
            for item in self {
                result.append(try await handler(item))
            }
            return result
        }.value
    }
}
