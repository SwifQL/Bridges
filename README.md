# Bridges

Work with Postgres and MySQL with SwifQL through their pure NIO drivers.

### Support Bridges development by giving a ⭐️

## Installation

It can be used on pure NIO2 app, but I have no example at the moment.

You could take a look at `VaporBridges` implementation as a reference to make it work in your pure NIO2 app.

### Vapor4 + PostgreSQL
```swift
.package(url: "https://github.com/SwifQL/PostgresBridge.git", from:"1.0.0-beta.1"),
.package(url: "https://github.com/SwifQL/VaporBridges.git", from:"1.0.0-beta.1"),
.target(name: "App", dependencies: ["Vapor", "PostgresBridge", "VaporBridges"]),
```

### Vapor4 + MySQL
```swift
.package(url: "https://github.com/SwifQL/MySQLBridge.git", from:"1.0.0-beta.1"),
.package(url: "https://github.com/SwifQL/VaporBridges.git", from:"1.0.0-beta.1"),
.target(name: "App", dependencies: ["Vapor", "MySQLBridge", "VaporBridges"]),
```

## Configuration

> TO BE DESCRIBED

## Models

> TO BE DESCRIBED

## Migrations

> TO BE DESCRIBED
