//
//  Dictionary+SwifQLable.swift
//  Bridges
//
//  Created by Mihael Isaev on 25.04.2020.
//

import Foundation
import SwifQL

extension Dictionary: SwifQLable where Key: Encodable, Value: Encodable {
    public var parts: [SwifQLPart] { [SwifQLPartUnsafeValue(self)] }
}
