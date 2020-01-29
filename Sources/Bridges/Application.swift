//
//  Application.swift
//  Bridges
//
//  Created by Mihael Isaev on 27.01.2020.
//

import Foundation
import Logging

public protocol BridgesApplication {
    var logger: Logger { get }
    var bridges: Bridges { get }
}
