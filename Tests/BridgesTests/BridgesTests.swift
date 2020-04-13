import XCTest
@testable import Bridges
import SwifQL

final class BridgesTests: XCTestCase {
    func testAll() {
        let kp1 = CarBrand.inSchema("deleted").$id
        XCTAssertEqual("\(kp1)", #""deleted"."CarBrand"."id""#)
        
        let kp2 = Deleted.carBrand.$id
        XCTAssertEqual("\(kp2)", #""deleted"."CarBrand"."id""#)
        
        let kp3 = \CarBrand.$name == SwifQLBool(true)
        XCTAssertEqual("\(kp3)", #""hello"."CarBrand"."name" = TRUE"#)
        
        let kp4 = CarBrand.as("cb").$name
        XCTAssertEqual("\(kp4)", #""cb"."name""#)
        
        let kp5 = CarBrand.inSchema("mike").as("cb").$id
        XCTAssertEqual("\(kp5)", #""cb"."id""#)
        
        struct MySchema: Schemable { static var schemaName: String { "my" } }
        let kp6 = CarBrand.inSchema(MySchema.self).$id
        XCTAssertEqual("\(kp6)", #""my"."CarBrand"."id""#)
        
        let aliasedTable = CarBrand.inSchema("mooo").as("mcb").table
        XCTAssertEqual("\(aliasedTable)", #""mooo"."CarBrand" AS "mcb""#)
        
        let cb = SwifQLAlias("cb")
        let subQueryWithAlias = |SwifQL.select(CarBrand.table.*).from(CarBrand.table)| => cb
        XCTAssertEqual("\(subQueryWithAlias)", #"(SELECT "hello"."CarBrand".* FROM "hello"."CarBrand") as "cb""#)
        XCTAssertEqual("\(cb.day)", #""cb"."day""#)
    }

    static var allTests = [
        ("testAll", testAll),
    ]
}

fileprivate struct Deleted: Schemable {
    static var schemaName: String { "deleted" }
    
    static var carBrand: Schema<CarBrand> { .init(schemaName) }
}

fileprivate final class CarBrand: Table, Schemable {
    static var schemaName: String { "hello" }
    
    @Column("id")
    var id: UUID

    @Column("name")
    var name: String
    
    @Column("createdAt")
    public var createdAt: Date

    @Column("updatedAt")
    public var updatedAt: Date

    @Column("deletedAt")
    public var deletedAt: Date?

    init () {}
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
