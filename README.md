<p align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-5.2-brightgreen.svg" alt="Swift 5.2">
    </a>
    <img src="https://img.shields.io/github/workflow/status/SwifQL/Bridges/test" alt="Github Actions">
    <a href="https://discord.gg/q5wCPYv">
        <img src="https://img.shields.io/discord/612561840765141005" alt="Swift.Stream">
    </a>
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

## Tables, Enums, and Structs

Let's start from `Enum` and `Struct`, and then use them in `Table`.

### Enum

Enum declaration is as simple as you can see below, just conform it to either `String` or `Int`, as well as to `BridgesEnum`

```swift
import Bridges

enum Gender: String, BridgesEnum {
    case male, female, other
}
```

or

```swift
import Bridges

enum Priority: Int, BridgesEnum {
    case high = 0
    case medium = 1
    case low = 2
}
```

### Struct

Struct declaration is simlar to Enum: just conform it to `SwifQLCodable`

```swift
import Bridges

struct AccountOptions: SwifQLCodable {
    var twoFactorAuthEnabled: Bool
    var lastPasswordChangeDate: Date
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

    @Column("account_options")
    var accountOptions: AccountOptions

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

By default Bridges creates table name like class name `User`. If you want to give table custom name use `tableName` static variable to set it:

```swift
final class User: Table {
    /// set any custom name here
    /// otherwise it will take the name of the table class (`User` in this case)
    static var tableName: String { "users" }

    @Column("id")
    var id: UUID

    // ...
```

Above example will create `users` table for class `User`.

## Migrations

### Table

To make it easy your migration struct should conform to `TableMigration`

```swift
struct CreateUser: TableMigration {
    /// set any custom name here
    /// otherwise it will take the name of the migration struct (`CreateUser` in this case)
    static var migrationName: String { "create_user_table" }

    typealias Table = User

    static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        createBuilder
            .column("id", .uuid, .primaryKey)
            .column("email", .text, .unique, .notNull)
            .column("name", .text, .notNull)
            .column("password", .text, .notNull)
            .column("gender", .auto(from: Gender.self), .notNull)
            .column("account_options", .jsonb, .notNull)
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

`migrationName` variable sets description of migration in `migrations` table after running it so Bridges knew which migrations were deployed and which need to be deployed in current batch.

**WARNING:** Although it is possible to use keypaths for columns `.column(\.$id, .uuid, .primaryKey)` you are strongly advised to use String typed column names `.column("id", .uuid, .primaryKey)` because later when you will have a lot of migrations with column renames you should be able to run the project from scratch and all the migrations will be run one by one and they should pass. If you will use keypaths they will fail.

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

Both `createBuilder` and `dropBuilder` have implemented security checks on creation and deletion of tables. Before creating a table you can force migration to check if there is no such table as you want to add to database. Same applies when you want to delete table to check if there is such table available.

```swift
struct CreateUser: TableMigration {
    typealias Table = User

    static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        createBuilder
            .checkIfNotExists()
            .column("id", .uuid, .primaryKey)
            // ...
            .execute(on: conn)
    }

    static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        dropBuilder
            .checkIfExists()
            .execute(on: conn)
    }
}
```

To update a table you could use `updateBuilder`

```swift
struct UpdateUser: TableMigration {
    typealias Table = User

    static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        updateBuilder
            // adds a check with constraint or expression
            .addCheck(...)
            // you could add new column same way as with `createBuilder`
            .addColumn(...)
            // adds foreign key
            .addForeignKey(...)
            // adds primary key to one or more columns
            .addPrimaryKey(...)
            // adds unique constraint to one or more columns
            .addUnique(...)
            // creates index
            .createIndex(...)
            // drops column
            .dropColumn(...)
            // drops default value at specified column
            .dropDefault(...)
            // drops index by its name
            .dropIndex(...)
            // drops constraint by its name
            .dropConstraint(...)
            // drops `not null` mark at specified column
            .dropNotNull(...)
            // renames column
            .renameColumn(...)
            // renames table
            .renameTable(...)
            // set default value for specified column
            .setDefault(...)
            // mark column as `not null`
            .setNotNull(...)
            // ...
            .execute(on: conn)
    }

    static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
        updateBuilder
            // use update builder to revert updates as well
            .execute(on: conn)
    }
}
```

### Enum

To make it easy your migration struct should conform to `EnumMigration`

```swift
struct CreateEnumGender: EnumMigration {
    /// set any custom name here
    /// otherwise it will take the name of the migration struct (`CreateEnumGender` in this case)
    static var migrationName: String { "CreateEnumGender" }

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

### Should I release connection?

No. Connection releases automatically.

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
