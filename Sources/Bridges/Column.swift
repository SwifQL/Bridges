//
//  Column.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import SwifQL

public protocol AnyColumn {
    var name: String { get }
    var type: SwifQL.`Type` { get }
    var `default`: ColumnDefault? { get }
    var constraints: [Constraint] { get }
    var inputValue: Encodable? { get }
    var isChanged: Bool { get }
    func encode(to encoder: Encoder) throws
    func decode(from decoder: Decoder) throws
}

@propertyWrapper
public final class Column<Value>: AnyColumn, ColumnRepresentable, Encodable where Value: Codable {
    public let name: String
    public let type: SwifQL.`Type`
    public let `default`: ColumnDefault?
    public let constraints: [Constraint]
    
    var outputValue: Value?
    public internal(set) var inputValue: Encodable?
    public var isChanged: Bool = false
    
    public var column: Column<Value> { self }
    
    public var projectedValue: Column<Value> { self }
    
    public var wrappedValue: Value {
        get {
            if let value = self.inputValue {
                return value as! Value
            } else if let value = self.outputValue {
                return value
            } else {
                fatalError("Cannot access field before it is initialized or fetched")
            }
        }
        set {
            self.inputValue = newValue
            self.isChanged = true
        }
    }
    
    /// Type will be selected automatically based on Swift type
    public init(_ name: String, default: ColumnDefault? = nil, constraints: Constraint...) {
        let autoType = Self.autoType(constraints)
        self.name = name
        self.type = autoType.type
        self.default = `default`
        var constraints = constraints
        if !autoType.isOptional, !constraints.contains(where: { $0.isNotNull || $0.isPrimaryKey }) {
            constraints.append(.notNull)
        }
        self.constraints = constraints
    }
    
    public init(name: String, type: SwifQL.`Type`, default: ColumnDefault? = nil, constraints: Constraint...) {
        self.name = name
        self.type = type
        self.default = `default`
        self.constraints = constraints
    }
    
    /// See `Codable`
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.wrappedValue)
    }

    public func decode(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let valueType = Value.self as? _Optional.Type {
            if container.decodeNil() {
                self.wrappedValue = (valueType._none as! Value)
            } else {
                self.wrappedValue = try container.decode(Value.self)
            }
        } else {
            self.wrappedValue = try container.decode(Value.self)
        }
        self.isChanged = false
    }
}

private protocol _Optional {
    static var _none: Any { get }
}

extension Optional: _Optional {
    static var _none: Any {
        return Self.none as Any
    }
}

public enum TimestampTrigger {
    case create
    case update
    case delete
}

//@propertyWrapper
//public final class Timestamp<Value>: AnyField, FieldRepresentable where Value: Codable {
//    public typealias Value = Date?
//
//    public let trigger: TimestampTrigger
//
//    public var name: String {
//        self.field.name
//    }
//    public let type: Type = .date
//
//    var inputValue: Encodable? {
//        get {
//            return self.field.inputValue
//        }
//        set {
//            self.field.inputValue = newValue
//        }
//    }
//
//    public var projectedValue: Timestamp {
//        return self
//    }
//
//    public var wrappedValue: Date? {
//        get {
//            return self.field.wrappedValue
//        }
//        set {
//            self.field.wrappedValue = newValue
//        }
//    }
//
//    public init(name: String, on trigger: TimestampTrigger) {
//        self.field = .init(name: name, type: .date)
//        self.trigger = trigger
//    }
//
//    public let field: BridgeColumn<Date?>
//}

///

public struct ColumnDefault {
    let query: SwifQLable
    
    init (_ query: SwifQLable) {
        self.query = query
    }
    
    public static func `default`(_ v: Any) -> ColumnDefault {
        var parts: [SwifQLPart] = []
        parts.append(o: .default)
        parts.append(o: .space)
        parts.append(safe: v)
        return .init(SwifQLableParts(parts: parts))
    }
    
    public static func `default`(_ expression: SwifQLable) -> ColumnDefault {
        var parts: [SwifQLPart] = []
        parts.append(o: .default)
        parts.append(o: .space)
        parts.append(contentsOf: expression.parts)
        return .init(SwifQLableParts(parts: parts))
    }
    
    public static func `default`(sequence name: String) -> ColumnDefault {
        .init(SwifQLableParts(parts: Op.custom(name)))
    }
}

public struct Constraint {
    let query: SwifQLable
    
    init (_ query: SwifQLable) {
        self.query = query
    }
    
    var isPrimaryKey = false
    var isNotNull = false
    
    public static var primaryKey: Constraint {
        var constraint = Constraint(SwifQL.primary.key)
        constraint.isPrimaryKey = true
        return constraint
    }
    
    public static var unique: Constraint {
        .init(SwifQL.unique)
    }
    
    public static var notNull: Constraint {
        var constraint = Constraint(SwifQL.not.null)
        constraint.isNotNull = true
        return constraint
    }
    
    public static func check(name: String? = nil, _ expression: SwifQLable) -> Constraint {
        var query = SwifQL
        if let name = name {
            query = query.constraint[any: Path.Column(name)]
        }
        return .init(query.check.values(expression))
    }
    
    public static func references<T: Table>(_ table: T.Type, onDelete: ReferentialAction? = nil, onUpdate: ReferentialAction? = nil) -> Constraint {
        references(table.tableName, onDelete: onDelete, onUpdate: onUpdate)
    }
    
    public static func references(_ table: String, onDelete: ReferentialAction? = nil, onUpdate: ReferentialAction? = nil) -> Constraint {
        var query = SwifQL.references[any: Path.Table(table)]
        if let action = onDelete {
            query = query.on.delete[any: action]
        }
        if let action = onUpdate {
            query = query.on.update[any: action]
        }
        return .init(query)
    }
}
