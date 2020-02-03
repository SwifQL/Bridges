//
//  BridgeEnumColumn+Equal.swift
//  Bridges
//
//  Created by Mihael Isaev on 02.02.2020.
//

import SwifQL

/// Allows to compare enum with enum column
/// ```swift
/// \User.$status == UserStatus.banned
/// ```
public func == <A, B>(lhs: KeyPath<A, B>, rhs: B.Value.RawValue) -> SwifQLable
    where A: Table, B: ColumnRepresentable, B.Value: BridgesEnum {
    SwifQLPredicate(operator: .equal, lhs: lhs, rhs: SwifQLableParts(parts: SwifQLPartSafeValue(rhs)))
}
