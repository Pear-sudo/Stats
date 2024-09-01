//
//  FolderMonitor.swift
//  Stats
//
//  Created by A on 01/09/2024.
//


import Foundation
import Combine
import AppKit
import CryptoKit

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