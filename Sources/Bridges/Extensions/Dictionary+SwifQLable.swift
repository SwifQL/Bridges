//
//  Dictionary+SQLable.swift
//  Bridges
//
//  Created by Mihael Isaev on 25.04.2020.
//

import Foundation
import SQL

extension Dictionary: @retroactive RowField, @retroactive SQLable where Key: Encodable, Value: Encodable {
    public var parts: [SQLPart] { [SQLPartUnsafeValue(self)] }
}
