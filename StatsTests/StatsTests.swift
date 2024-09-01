//
//  StatsTests.swift
//  StatsTests
//
//  Created by A on 30/08/2024.
//

import Testing
@testable import Stats

struct StatsTests {

    @Test func example() async throws {
        let timestamp = BackupManager.backupTimestamp
        // 2024-08-31_22-05-24_GMT_08-00_875154018
        let pattern = /^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_GMT_\d{2}-\d{2}_\d{9}$/
        #expect(timestamp.contains(pattern))
    }

}
