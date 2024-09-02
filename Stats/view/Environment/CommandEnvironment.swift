//
//  CommandEnvironment.swift
//  Stats
//
//  Created by A on 02/09/2024.
//

import Foundation
import SwiftUI
import Combine

enum Command {
    case unknown
    case start, enter
}

typealias CommandSubject = PassthroughSubject<Command, Never>

extension EnvironmentValues {
    @Entry var commands: CommandSubject = .init()
}
