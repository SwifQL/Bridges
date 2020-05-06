//
//  DatabaseMigrations.swift
//  Bridges
//
//  Created by Mihael Isaev on 28.01.2020.
//

import Foundation
import Logging
import NIO

public protocol Migrator {
    func add(_ migration: AnyMigration.Type)
    
    func migrate() -> EventLoopFuture<Void>
    func revertLast() -> EventLoopFuture<Void>
    func revertAll() -> EventLoopFuture<Void>
}

public class BridgeDatabaseMigrations<B: Bridgeable>: Migrator {
    var migrations: [AnyMigration.Type] = []
    let bridge: B
    let db: DatabaseIdentifier
    let dedicatedSchema: Bool
    
    public func add(_ migration: AnyMigration.Type) {
        migrations.append(migration)
    }
    
    public init(_ bridge: B, db: DatabaseIdentifier, dedicatedSchema: Bool = false) {
        self.bridge = bridge
        self.db = db
        self.dedicatedSchema = dedicatedSchema
    }
    
    struct BridgesSchema: Schemable {
        static var schemaName: String { "bridges" }
        
        struct Create: SchemaMigration {
            typealias Schema = BridgesSchema
            
            static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
                createBuilder.checkIfNotExists().execute(on: conn)
            }
            
            static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
                dropBuilder.execute(on: conn)
            }
        }
    }
    
    struct Migrations: Table {
        static var tableName: String { "migrations" }
        
        @Column("id")
        var id: Int64
        
        @Column("name")
        var name: String
        
        @Column("batch")
        var batch: Int
        
        struct Create: TableMigration {
            typealias Table = Migrations
            
            static func prepare(on conn: BridgeConnection) -> EventLoopFuture<Void> {
                createBuilder
                    .checkIfNotExists()
                    .column(\.$id, .bigserial, .primaryKey)
                    .column(\.$name, .text, .unique)
                    .column(\.$batch, .int)
                    .execute(on: conn)
            }
            
            static func revert(on conn: BridgeConnection) -> EventLoopFuture<Void> {
                dropBuilder.checkIfExists().execute(on: conn)
            }
        }
    }
    
    private var schemaName: String { dedicatedSchema ? "bridges" : "public" }
    private var m: Schema<Migrations> { Schema<Migrations>(schemaName) }
    
    public func migrate() -> EventLoopFuture<Void> {
        return bridge.transaction(to: db, on: bridge.eventLoopGroup.next()) { conn in
            conn.eventLoop.future().flatMap {
                self.dedicatedSchema
                    ? BridgesSchema.Create.prepare(on: conn)
                    : conn.eventLoop.future()
            }.flatMap {
                CreateTableBuilder<Migrations>(schema: self.schemaName)
                    .checkIfNotExists()
                    .column(\.$id, .bigserial, .primaryKey)
                    .column(\.$name, .text, .unique)
                    .column(\.$batch, .int)
                    .execute(on: conn)
            }.flatMap {
                let query = SwifQL.select(self.m.table.*).from(self.m.table).prepare(conn.dialect).plain
                return conn.query(raw: query, decoding: Migrations.self).flatMap { completedMigrations in
                    let batch = completedMigrations.map { $0.batch }.max() ?? 0
                    var migrations = self.migrations
                    migrations.removeAll { m in completedMigrations.contains { $0.name == m.migrationName } }
                    return migrations.map { migration in
                        {
                            migration.prepare(on: conn).flatMap {
                                SwifQL
                                    .insertInto(self.m.table, fields: self.m.$name, self.m.$batch)
                                    .values
                                    .values(migration.migrationName, batch + 1)
                                    .execute(on: conn)
                            }
                        }
                    }.flatten(on: conn.eventLoop)
                }
            }
        }
    }

    public func revertLast() -> EventLoopFuture<Void> {
        bridge.transaction(to: db, on: bridge.eventLoopGroup.next()) {
            self._revertLast(on: $0).transform(to: ())
        }
    }
    
    private func _revertLast(on conn: BridgeConnection) -> EventLoopFuture<Bool> {
        let query = SwifQL.select(self.m.table.*).from(self.m.table).prepare(conn.dialect).plain
        return conn.query(raw: query, decoding: Migrations.self).flatMap { completedMigrations in
            guard let lastBatch = completedMigrations.map({ $0.batch }).max()
                else { return conn.eventLoop.future(false) }
            let migrationsToRevert = completedMigrations.filter { $0.batch == lastBatch }
            var migrations = self.migrations
            migrations.removeAll { m in migrationsToRevert.contains { $0.name != m.migrationName } }
            return migrations.map { migration in
                {
                    migration.revert(on: conn).flatMap {
                        SwifQL
                            .delete(from: self.m.table)
                            .where(self.m.$name == migration.migrationName)
                            .execute(on: conn)
                    }
                }
            }.flatten(on: conn.eventLoop).transform(to: true)
        }
    }
    
    public func revertAll() -> EventLoopFuture<Void> {
        bridge.transaction(to: db, on: bridge.eventLoopGroup.next()) { conn in
            let promise = conn.eventLoop.makePromise(of: Void.self)
            func revert() {
                self._revertLast(on: conn).whenComplete { res in
                    switch res {
                    case .success(let reverted):
                        if reverted {
                            revert()
                        } else {
                            promise.succeed(())
                        }
                    case .failure(let error):
                        promise.fail(error)
                    }
                }
            }
            revert()
            return promise.futureResult
        }
    }
}

// TODO: implement migration lock
//Notes about locks
//
//A lock system is there to prevent multiple processes from running the same migration batch in the same time. When a batch of migrations is about to be run, the migration system first tries to get a lock using a SELECT ... FOR UPDATE statement (preventing race conditions from happening). If it can get a lock, the migration batch will run. If it can't, it will wait until the lock is released.
//
//Please note that if your process unfortunately crashes, the lock will have to be manually removed in order to let migrations run again. The locks are saved in a table called "tableName_lock"; it has a column called is_locked that you need to set to 0 in order to release the lock. The index column in the lock table exists for compatibility with some database clusters that require a primary key, but is otherwise unused.

/// Move migrations table from public to bridges schema
//    let om = Schema<Migrations>("public")
//    let move = SwifQL
//        .insertInto(Migrations.table, fields: \Migrations.$id, \Migrations.$name, \Migrations.$batch)
//        .select(om.$id, om.$name, om.$batch)
//        .from(om.table)
//    let drop = SwifQL.drop.table[any: om.table]
//    return move.execute(on: conn).flatMap {
//        drop.execute(on: conn)
//    }
