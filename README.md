<p align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.2-brightgreen.svg" alt="Swift 5.2">
    </a>
    <img src="https://img.shields.io/github/workflow/status/SwifQL/Bridges/test" alt="Github Actions">
</p>

# Bridges

Work with Postgres and MySQL with SwifQL through their pure NIO drivers.

### Support Bridges development by giving a ⭐️

## Installation

It can be used on pure NIO2 app, but I have no example at the moment.

You could take a look at `VaporBridges` implementation as a reference to make it work in your pure NIO2 app.

### Vapor4 + PostgreSQL
```swift
.package(url: "https://github.com/SwifQL/PostgresBridge.git", from:"1.0.0-rc"),
.package(url: "https://github.com/SwifQL/VaporBridges.git", from:"1.0.0-rc"),
.target(name: "App", dependencies: [
    .product(name: "Vapor", package: "vapor"),
    .product(name: "PostgresBridge", package: "PostgresBridge"),
    .product(name: "VaporBridges", package: "VaporBridges")
]),
```

### Vapor4 + MySQL
```swift
.package(url: "https://github.com/SwifQL/MySQLBridge.git", from:"1.0.0-rc"),
.package(url: "https://github.com/SwifQL/VaporBridges.git", from:"1.0.0-rc"),
.target(name: "App", dependencies: [
    .product(name: "Vapor", package: "vapor"),
    .product(name: "MySQLBridge", package: "MySQLBridge"),
    .product(name: "VaporBridges", package: "VaporBridges")
]),
```

# Documentation

All the examples below will be for Vapor 4 and PostgreSQL but you can implement it for MySQL and any other framework the same way.

## Logger

You could set log level e.g. in `configure.swift`
```swift
// optionally set global application log level before setting bridges log level
app.logger.logLevel = .notice
app.bridges.logger.logLevel = .debug
```
## Configuration

Initialize (but it is not required) connection pool to your databases right before your app launch (in `configure.swift`)

Otherwise poll will be created when you first time try to get a connection to your database.

```swift
app.postgres.register(.psqlEnvironment)
```

Here `.psqlEnvironment` is an identifier to your database.

It is kinda default automatic identifier based on environment vars which expects the following env vars:
```
PG_DB
PG_HOST - optional, 127.0.0.1 by default
PG_PORT - optional, 5432 by default
PG_USER - optional, `postgres` by default
PG_PWD - optional, empty string by default (will fix it to nil by default)
```
so `PG_DB` is the only one required env var to make this automatic identifier work.

You can create your own identifiers for all your databases and even different hosts simply by write this kind of extensions

```swift
extension DatabaseIdentifier {
    public static var myDb1: DatabaseIdentifier {
        .init(name: "my-db1", host: .myMasterHost, maxConnectionsPerEventLoop: 1)
    }
    public static var myDb1Slave: DatabaseIdentifier {
        .init(name: "my-db1", host: .mySlaveHost, maxConnectionsPerEventLoop: 1)
    }
}
extension DatabaseHost {
    public static var myMasterHost: DatabaseHost {
        return .init(hostname: "127.0.0.1", username: "<username>", password: "<password or nil>", port: 5432, tlsConfiguration: nil)
    }
    public static var mySlaveHost: DatabaseHost {
        return .init(hostname: "192.168.0.200", username: "<username>", password: "<password or nil>", port: 5432, tlsConfiguration: nil)
    }
}
```

Once you configured database connections you're ready to start working with them.

## Tables and Enums

Let's start from `Enum` and then use it in `Table`.

### Enum

Enum declaration is as simple as you can see below, just conform it to `String` and `BridgesEnum`

```swift
import Bridges

enum Gender: String, BridgesEnum {
    case male, female, other
}
```

### Table

The main thing is to conform your model to `Table` and use `@Column` for all its fields

```swift
import Bridges

final class User: Table {
    @Column("id")
    var id: UUID

    @Column("email")
    var email: String

    @Column("name")
    var name: String

    @Column("password")
    var password: String

    @Column("gender")
    var gender: Gender

    @Column("createdAt")
    public var createdAt: Date

    @Column("updatedAt")
    public var updatedAt: Date

    @Column("deletedAt")
    public var deletedAt: Date?

    /// See `Table`
    init () {}
}
```

## Migrations

### Table

To make it easy your migration struct should conform to `TableMigration`

```swift
struct CreateUser: TableMigration {
    /// set any custom name here
    /// otherwise it will take the name of the migration struct (`CreateUser` in this case)
    static var name: String { "CreateUser" }

    typealias Table = User

    static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        createBuilder
            .column("id", .uuid, .primaryKey)
            .column("email", .text, .unique, .notNull)
            .column("name", .text, .notNull)
            .column("password", .text, .notNull)
            .column("createdAt", .timestamptz, .default(Fn.now()), .notNull)
            .column("updatedAt", .timestamptz, .notNull)
            .column("deletedAt", .timestamptz)
            .execute(on: conn)
    }

    static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        dropBuilder.execute(on: conn)
    }
}
```

And yes, you can use keypaths for columns `.column(\.$id, .uuid, .primaryKey)` but it is not good for long perspective.

`.column()` is powerful, you can set name, type, default value and constraints here

Example for rating column with check constraints
```swift
.column(\.$rating, .int, .notNull, .check(\WorkerReview.$rating >= 0 && \WorkerReview.$rating <= 5))
```

Example for column with reference(foreign key) constraint
```swift
.column("workerId", .uuid, .notNull, .references(Worker.self, onDelete: .cascade, onUpdate: .noAction))
```
Also I should say that in `TableMigration` we have `createBuilder`, `updateBuilder` and `dropBuilder`

In examples above you can see how to use `createBuilder` and `dropBuilder`

> Unfortunately `updateBuilder` haven't been implemented yet, but will be implemented very soon!

### Enum

To make it easy your migration struct should conform to `EnumMigration`

```swift
struct CreateEnumGender: EnumMigration {
    /// set any custom name here
    /// otherwise it will take the name of the migration struct (`CreateEnumGender` in this case)
    static var name: String { "CreateEnumGender" }

    typealias Enum = Gender

    static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        createBuilder
            .add(.male, .female, .other)
            .execute(on: conn)
    }

    static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        dropBuilder.execute(on: conn)
    }
}
```

You also can use raw strings with ``.add()`` method like this
```swift
createBuilder
    .add("male", "female", "other")
    .execute(on: conn)
```

As you can see we also have `createBuilder` and `dropBuilder` here, but here we also have fully working `updateBuilder`
```swift
// to add one value in the end
updateBuilder.add("bigender").execute(on: conn)
// to add multiple values
updateBuilder.add("bigender").add("mtf", after: "male").add("ftm", before: "female")
```

### Migrations execution

I prefer to create `migrations.swift`  near `configure.swift` since we execute migrations before app lauch

```swift
// migrations.swift
import Vapor
import PostgresBridge

func migrations(_ app: Application) throws {
    // create `migrations` object on your database connection
    let migrator = app.postgres.migrator(for: .myDb1)

    // Enums

    migrator.add(CreateEnumGender.self) // to create `Gender` enum type in db

    // Models

    migrator.add(CreateUser.self) // to create `User` table

    // migrator.add(SomeCustomMigration.self) // could be some seed migration :)

    try migrator.migrate().wait() // will run all provided migrations one by one inside a transaction
//    try migrator.revertLast().wait() // will revert only last batch
//    try migrator.revertAll().wait() // will revert all migrations one by one in desc order
}
```
then run them somewhere in the end of configure.swift
```swift
// Called before your application initializes.
public func configure(_ app: Application) throws {
    // some initializations

    try migrations(app)
    try routes(app)
}
```

## Queries

Use the full power of `SwifQL` to build your queries. Once query is ready execute it on connection.

> 💡You can get connection on both `Application` and `Request` objects.

Example for `Application` object e.g. for `configure.swift` file
```swift
// Called before your application initializes.
public func configure(_ app: Application) throws {
    app.postgres.connection(to: .myDb1) { conn in
        SwifQL.select(User.table.*).from(User.table).execute(on: conn).all(decoding: User.self).flatMap { rows in
            print("yaaay it works and returned \(rows.count) rows!")
        }
    }.whenComplete {
        switch $0 {
        case .success: print("query was successful")
        case .failure(let error): print("query failed: \(error)")
        }
    }
}
```

Example for `Request` object

> 💡`User` table model should be conformed to `Content` protocol to be returned as request response

```swift
func routes(_ app: Application) throws {
    app.get("users") { req -> EventLoopFuture<[User]> in
        req.postgres.connection(to: .myDb1) { conn in
            SwifQL.select(User.table.*).from(User.table).execute(on: conn).all(decoding: User.self)
        }
    }
}
```

### Transactions

You could execute several queries inside transaction

```swift
app.postgres.transaction(to: .myDb1) { conn in
    /// `BEGIN` calls automatically

    /// do any amount of queries here

    /// once you finish if everything is ok then `COMMIT` calls automatically

    /// if error has occured then `ROLLBACK` calls automatically
}
```

### Should I close connection?

Connection closes automatically.

### Conveniences

#### Select
```swift
User.select.where(\User.$email == "hello@gmail.com").execute(on: conn).first(decoding: User.self)
```

#### Insert
```swift
let user = User(email: "hello@gmail.com", name: "John", password: "qwerty".sha512, gender: .male)
user.insert(on: conn)
```

#### Batch insert
```swift
let user1 = User(email: "hello@gmail.com", name: "John", password: "qwerty".sha512, gender: .male)
let user2 = User(email: "byebye@gmail.com", name: "Amily", password: "asdfgh".sha512, gender: .female)
let user3 = User(email: "trololo@gmail.com", name: "Trololo", password: "zxcvbn".sha512, gender: .other)
[user1, user2, user3].batchInsert(on: conn)
```

#### Update
```swift
User.select.where(\User.$email == "hello@gmail.com").execute(on: conn).first(decoding: User.self).flatMap { user in
    guard let user = user else { return conn.eventLoop.makeFailedFuture(...) }
    user.password = "asdfg"
    return user.update(on: \.$id, on: conn) // executes update just for `password` column and returns EventLoopFuture<User>
}
```

#### Delete
```swift
user.delete(on: \.$id, on: conn) // executes `DELETE FROM User WHERE id=...` returns EventLoopFuture<Void>
```

## Contributing

Please feel free to contribute

## Contacts

File an issue or you always can find me in Discord on Vapor server in `#swifql` branch or directly as `iMike#3049`.
