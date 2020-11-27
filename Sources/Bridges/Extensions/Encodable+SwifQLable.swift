//
//  Encodable+SwifQLable.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.11.2020.
//

import Foundation
import SwifQL

extension Encodable {
    var swifQLable: SwifQLable? {
        if let v = (self as Any) as? [AnySwifQLEnum] {
            let values = v.compactMap { $0.anyRawValue as? String }.joined(separator: ",")
            let preparedPart = SwifQLPartSafeValue("{\(values)}")
            return SwifQLableParts(parts: [preparedPart])
        } else if let v = self as? SwifQLPart {
            return SwifQLableParts(parts: [v])
        } else if let v = self as? SwifQLable {
            return v
        } else if let v = self as? Bool {
            return SwifQLBool(v)
        } else {
            return nil
        }
    }
}
