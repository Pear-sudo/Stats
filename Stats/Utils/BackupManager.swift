//
//  BackupManager.swift
//  Stats
//
//  Created by A on 01/09/2024.
//

import Foundation
import Combine
import AppKit
import CryptoKit

@Observable
class BackupManager {
    
    static let modelContext = sharedModelContest
    
    static let `default`: BackupManager = BackupManager(backupDir: SQLite, fileToBackup: database, autoBackup: true)
        
    init(backupDir: URL, fileToBackup: URL, autoBackup: Bool = false) {
        self.backupDir = backupDir
        self.fileToBackup = fileToBackup
        self.folderMonitor = FolderMonitor(url: backupDir)
        self.folderMonitor.folderDidChange = { [weak self] in
            /*
             I have no idea why stats will be updated without folder monitor
             If in the future, the UI does not update, try annotate the class with @Observable and propagate the change of this date to the calculation of stats
             */
            self?.backupDirChangeDate = .now
        }
        self.folderMonitor.startMonitoring()
        BackupManager.initFiles()
        if autoBackup {
            self.autoBackup()
        }
    }
    
    private let backupDir: URL
    private let fileToBackup: URL
    static private let fileManager =  FileManager.default
    @ObservationIgnored private var fileManager: FileManager {
        return BackupManager.fileManager
    }
    
    @ObservationIgnored private let calendar = Calendar.current
    
    private var backupDirChangeDate: Date?
    @ObservationIgnored private var backupStatsCacheDate: Date?
    @ObservationIgnored private var backupStatsCache: BackupStats?
    @ObservationIgnored private var folderMonitor: FolderMonitor
    
    static var container: String {
        NSHomeDirectory()
    }
    static var containerURL: URL {
        URL(filePath: container, directoryHint: .isDirectory)
    }
    static var autoBackupURL: URL {
        containerURL.appending(component: "AutoBackups", directoryHint: .isDirectory)
    }
    static var SQLite: URL {
        autoBackupURL.appending(component: "SQLite", directoryHint: .isDirectory)
    }
    static var database: URL {
        modelContext.container.configurations.first!.url
    }
    
    static var fileNames: [FileName] {
        [
            FileName(name: "App sandbox", url: containerURL),
            FileName(name: "Auto backup", url: autoBackupURL),
            FileName(name: "SQLite", url: SQLite),
            FileName(name: "Default SQLite", url: database, shouldBeCreated: false)
        ]
    }
    
    static private func initFiles() {
        for fileName in fileNames.filter({$0.shouldBeCreated}) {
            let url = fileName.url
            if !exist(url: url) {
                if url.hasDirectoryPath {
                    try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
                }
            }
        }
    }
    
    static func exist(url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path(percentEncoded: false))
    }
    
    static var backupTimestamp: String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss_ZZZZ"
        dateFormatter.timeZone = TimeZone.current
        var dateString = dateFormatter.string(from: date)
        
        dateString = dateString.replacingOccurrences(of: "+", with: "_")
        dateString = dateString.replacingOccurrences(of: ":", with: "-")

        let nanoseconds = Int((date.timeIntervalSince1970.truncatingRemainder(dividingBy: 1)) * 1_000_000_000)
        
        return "\(dateString)_\(String(format: "%09d", nanoseconds))"
    }
    
    @ObservationIgnored private let maxBackups = 20
        
    func backup() {
        guard let stats = getBackupStats(), let latest = stats.latestBackupURL else {
            copyBackup()
            return
        }
        
        if sameFilesByHash(fileToBackup, latest) {
            linkBackup(at: latest)
        } else {
            copyBackup()
        }
        
        if stats.count < maxBackups { // note we now have one additional file
            return
        } else if stats.count > maxBackups {
            deleteOldest(count: stats.count - maxBackups + 1)
            return
        }
        
        guard let oldest = stats.oldestBackupURL else {
            return
        }
        do {
            try fileManager.removeItem(at: oldest)
        } catch {
            print("Cannot remove item")
        }
    }
    
    private func linkBackup(at: URL) {
        do {
            try fileManager.linkItem(at: at, to: backupURL)
        } catch {
            print("Cannot create hard link")
        }
    }
    
    private func copyBackup() {
        do {
            try fileManager.copyItem(at: fileToBackup, to: backupURL)
        } catch {
            print("Backup failed with error: \(error)")
        }
    }
    
    private var backupURL: URL {
        backupDir.appending(path: "Stats_\(BackupManager.backupTimestamp).sqlite3", directoryHint: .notDirectory)
    }
    
    private func sameFilesByHash(_ file1: URL, _ file2: URL) -> Bool {
        do {
            return try hashFile(file1) == hashFile(file2)
        } catch {
            return false
        }
    }
    
    private func hashFile(_ url: URL) throws -> Insecure.MD5Digest {
        let chunkSize = 4096
        var hasher = Insecure.MD5()
        do {
            let fileHandle = try FileHandle(forReadingFrom: url)
            defer {
                do {
                    try fileHandle.close()
                } catch {
                    print("Cannot close file")
                }
            }
            
            while let data = try fileHandle.read(upToCount: chunkSize), !data.isEmpty {
                hasher.update(data: data)
            }
            
        } catch {
            print("Failed to read file: \(error)")
            throw error
        }
        return hasher.finalize()
    }
    
    var backupStats: BackupStats? {
//        let _ = backupDirChangeDate
        return getBackupStats()
    }
    
    @discardableResult
    private func deleteOldest(count: Int) -> Int? {
        var deletionCount = 0
        let resourceKeys = Set<URLResourceKey>([.nameKey, .creationDateKey])
        do {
            let files = try fileManager.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: Array(resourceKeys))
            var valid = files.compactMap { file -> (URL, Date)? in
                guard let resourceValues = try? file.resourceValues(forKeys: resourceKeys),
                      let name = resourceValues.name,
                      let creationDate = resourceValues.creationDate
                else {
                    return nil
                }
                if !name.contains(pattern) {
                    return nil
                }
                return (file, creationDate)
            }
            valid.sort(by: {$0.1 < $1.1})
            valid.prefix(count).forEach { url, _ in
                do {
                    try fileManager.removeItem(at: url)
                    deletionCount += 1
                } catch {
                    print("Cannot delete the item")
                }
            }
        } catch {
            print("Cannot read dir")
            return nil
        }
        return deletionCount
    }
    
    // 2024-08-31_22-05-24_GMT_08-00_875154018.sqlite3
    private let pattern = /^Stats_(\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_)(GMT_\d{2}-\d{2})_(\d{9})\.sqlite3$/
    
    private func getBackupStats() -> BackupStats? {
        if backupStatsCache != nil && (backupDirChangeDate == nil || backupDirChangeDate! < backupStatsCacheDate!) {
            return backupStatsCache
        }
        
        let resourceKeys = Set<URLResourceKey>([.isDirectoryKey, .nameKey])
        guard let directoryEnumerator = BackupManager.fileManager.enumerator(at: backupDir, includingPropertiesForKeys: Array(resourceKeys), options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]) else {
            print("Failed to init directoryEnumerator")
            return nil
        }
        
        var latestBackupDate = Date.distantPast
        var latestBackupURL: URL? = nil
        var oldestBackupDate = Date.distantFuture
        var oldestBackupURL: URL? = nil
        
        var count = 0

        for case let fileURL as URL in directoryEnumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                let isDirectory = resourceValues.isDirectory,
                !isDirectory,
                let name = resourceValues.name
                else {
                    continue
            }
            guard let match = name.firstMatch(of: pattern) else { continue }
            
            var timezoneStr = match.2
            timezoneStr.replace("_", with: "+")
            timezoneStr.replace("-", with: ":")
            let dateStr = "\(match.1)\(timezoneStr)"
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss_ZZZZ"
            guard var date = dateFormatter.date(from: dateStr) else { continue }
            let nanoseconds = Double(match.3)! / 1_000_000_000
            date.addTimeInterval(nanoseconds)
            
            if date > latestBackupDate {
                latestBackupDate = date
                latestBackupURL = fileURL
            }
            
            if date < oldestBackupDate {
                oldestBackupDate = date
                oldestBackupURL = fileURL
            }
            
            count += 1
        }
        
        backupStatsCacheDate = .now
        
        let stats = BackupStats(count: count,
                           latestBackupDate: latestBackupDate,
                           latestBackupURL: latestBackupURL,
                           oldestBackupDate: oldestBackupDate,
                           oldestBackupURL: oldestBackupURL
        )
        backupStatsCache = stats
        
        return stats
    }
    
    private func autoBackup() {
        autoBackupForToday()
        setupAutoBackupWhenTerminate()
        setupAutoBackupForFuture()
    }
    
    @ObservationIgnored private let sharedNotificationCenter = NSWorkspace.shared.notificationCenter
    @ObservationIgnored private var areObserversAdded = false
    
    private func setupAutoBackupForFuture() {
        if !areObserversAdded {
            sharedNotificationCenter.addObserver(self, selector: #selector(systemDidWake), name: NSWorkspace.didWakeNotification, object: nil)
            sharedNotificationCenter.addObserver(self, selector: #selector(systemWillSleep), name: NSWorkspace.willSleepNotification, object: nil)
            sharedNotificationCenter.addObserver(self, selector: #selector(screensDidWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
            sharedNotificationCenter.addObserver(self, selector: #selector(screensDidSleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
            
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenIsLocked), name: Notification.Name("com.apple.screenIsLocked"), object: nil)
            DistributedNotificationCenter.default().addObserver(self, selector: #selector(screenIsUnlocked), name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)

            
            areObserversAdded = true
        }
    }
    
    /*
     Some notes about the order of these notifications:
     System will sleep
     Screen is sleep
     Screen is locked
     Screen is woke up
     System woke up
     Screen is unlocked
     */
    
    @objc private func systemDidWake() {
        print("System woke up")
    }
    
    @objc private func systemWillSleep() {
        print("System will sleep")
    }
    
    @objc private func screenIsLocked() {
        print("Screen is locked")
    }

    @objc private func screenIsUnlocked() {
        print("Screen is unlocked")
        autoBackupForToday()
    }
    
    @objc private func screensDidWake() {
        print("Screen is woke up")
    }
    
    @objc private func screensDidSleep() {
        print("Screen is sleep")
    }
    
    @discardableResult
    private func autoBackupForToday() -> Bool {
        guard let stats = getBackupStats() else {
            return false
        }
        guard let latestBackupDate = stats.latestBackupDate else {
            if stats.count == 0 {
                backup()
                return true
            } else {
                return false
            }
        }
        if !calendar.isDateInToday(latestBackupDate) {
            backup()
        }
        return true
    }
    
    @ObservationIgnored private var willTerminateCancellable: AnyCancellable?
    
    @discardableResult
    private func setupAutoBackupWhenTerminate() -> Bool {
        willTerminateCancellable = NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] notification in
                defer {
                    self?.willTerminateCancellable?.cancel()
                }
                self?.backup()
            }
        return true
    }
}

struct BackupStats {
    var count: Int
    
    var latestBackupDate: Date?
    var latestBackupURL: URL?
    
    var oldestBackupDate: Date?
    var oldestBackupURL: URL?
}

struct FileName: Identifiable, Hashable {
    var name: String
    var url: URL
    var shouldBeCreated: Bool = true
    var id: Self {
        self
    }
}

class FolderMonitor {
    
    private var monitoredFolderFileDescriptor: CInt = -1
    private let folderMonitorQueue = DispatchQueue(label: "FolderMonitorQueue", attributes: .concurrent)
    private var folderMonitorSource: DispatchSourceFileSystemObject?
    let url: Foundation.URL
    
    init(url: Foundation.URL) {
        self.url = url
    }
    
    var folderDidChange: (() -> Void)?
    
    func startMonitoring() {
        guard folderMonitorSource == nil && monitoredFolderFileDescriptor == -1 else {
            return
            
        }
        monitoredFolderFileDescriptor = open(url.path, O_EVTONLY)
        folderMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: monitoredFolderFileDescriptor, eventMask: [.write, .link], queue: folderMonitorQueue)
        
        folderMonitorSource?.setEventHandler { [weak self] in
            self?.folderDidChange?()
        }
        
        folderMonitorSource?.setCancelHandler { [weak self] in
            guard let strongSelf = self else { return }
            close(strongSelf.monitoredFolderFileDescriptor)
            strongSelf.monitoredFolderFileDescriptor = -1
            strongSelf.folderMonitorSource = nil
        }
        
        folderMonitorSource?.resume()
    }
    
    func stopMonitoring() {
        folderMonitorSource?.cancel()
    }
}
