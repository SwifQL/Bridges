//
//  Encodable+SQLable.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.11.2020.
//

import Foundation
import SQL

extension Encodable {
    var swifQLable: SQLable? {
        if let v = (self as Any) as? [AnySQLEnum] {
            let values = v.compactMap { $0.anyRawValue as? String }.joined(separator: ",")
            let preparedPart = SQLPartSafeValue("{\(values)}")
            return SQLableParts(parts: [preparedPart])
        } else if let v = self as? SQLPart {
            return SQLableParts(parts: [v])
        } else if let v = self as? SQLable {
            return v
        } else if let v = self as? Bool {
            return SQLBool(v)
        } else {
            return nil
        }
    }
}
