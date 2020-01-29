//
//  ConnectionSource.swift
//  Bridges
//
//  Created by Mihael Isaev on 28.01.2020.
//

import Foundation

public protocol BridgesConnectionSource {
    init (_ db: DatabaseIdentifier)
}
