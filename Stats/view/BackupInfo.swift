//
//  BackupInfo.swift
//  Stats
//
//  Created by A on 31/08/2024.
//

import SwiftUI
import Foundation
import Combine

struct BackupInfo: View {
    @State private var selections = Set<FileName>()
    @Environment(\.modelContext) private var modelContext
    @State private var backupInProgress: Bool = false
    private let fileManager =  FileManager.default
    private let backupManager = BackupManager.default
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                if let stats = backupManager.backupStats {
                    Group {
                        Text("Total: \(stats.count)")
                        if let latestBackupDate = stats.latestBackupDate, let latestBackupURL = stats.latestBackupURL {
                            Text("Latest: \(latestBackupDate.formatted())")
                                .lineLimit(1)
                                .openURL(latestBackupURL)
                        }
                    }
                    .foregroundStyle(.secondary)
                } else {
                    Text("Cannot get backup stats")
                        .foregroundStyle(.red)
                }
                
                Spacer()
                
                ShortLayout(anchor: 0) {
                    Button(backupInProgress ? "Backing Up..." : "Backup Now") {
                        Task {
                            backupInProgress = true
                            backupManager.backup()
                            backupInProgress = false
                        }
                    }
                    .disabled(backupInProgress)
                    Rectangle()
                        .fill(.clear)
                        .aspectRatio(contentMode: .fit)
                        .overlay {
                            if backupInProgress {
                                ProgressView()
                                    .scaleEffect(0.5)
                            }
                        }
                }
            }
            
            Table(of: FileName.self, selection: $selections) {
                
                TableColumn("Name") { filename in
                    Text(filename.name)
                }
                
                TableColumn("URL") { filename in
                    HStack {
                        Text(filename.url.path(percentEncoded: false))
                        if BackupManager.exist(url: filename.url) {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                        } else {
                            Image(systemName: "x.circle")
                                .foregroundStyle(.red)
                        }
                    }
                    .openURL(filename.url)
                }
                
            } rows: {
                ForEach(BackupManager.fileNames) { filename in
                    TableRow(filename)
                }
            }
            
        }
        .padding()
        .onAppear {
            doInit()
        }
    }
    
    private func mockBackup(seconds: Double = 3) async {
        do {
            try await Task.sleep(for: .seconds(seconds))
        }
        catch is CancellationError {
            print("Cancelled")
        }
        catch {}
    }
    
    private func doInit() {
        
    }
}

struct OpenFile: ViewModifier {
    var url: URL
    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button("Open") {
                    if url.hasDirectoryPath {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path(percentEncoded: false))
                    } else {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
                Button("Open Terminal") {
                    if url.hasDirectoryPath {
                        openTerminal(at: url)
                    } else {
                        let dir = url.deletingLastPathComponent()
                        openTerminal(at: dir)
                    }
                }
            }
    }
    
    @available(OSX 10.15, *)
    public func openTerminal(at url: URL?){
        guard let url = url,
              let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal")
        else { return }
        
        NSWorkspace.shared.open([url], withApplicationAt: appUrl, configuration: NSWorkspace.OpenConfiguration() )
    }
}

extension View {
    func openURL(_ url: URL) -> some View {
        modifier(OpenFile(url: url))
    }
}

#Preview {
    BackupInfo()
}
