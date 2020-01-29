//
//  ColumnRepresentable.swift
//  Bridges
//
//  Created by Mihael Isaev on 28.01.2020.
//

import Foundation

public protocol ColumnRepresentable {
    associatedtype Value: Codable
    var column: Column<Value> { get }
}
