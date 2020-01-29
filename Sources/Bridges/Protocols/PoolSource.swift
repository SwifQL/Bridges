//
//  PoolSource.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import AsyncKit

public protocol BridgesPoolSource: ConnectionPoolSource {
    init (_ db: DatabaseIdentifier)
}
