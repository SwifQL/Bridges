//
//  BridgesError.swift
//  Bridges
//
//  Created by Mihael Isaev on 31.01.2020.
//

import Foundation

public enum BridgesError: Error {
    case failedToDecodeWithReturning
    case valueIsNilInKeyColumnUpdateIsImpossible
    case nonGenericDatabaseIdentifier
}
