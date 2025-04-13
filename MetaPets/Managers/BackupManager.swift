//
//  BackupManager.swift
//  Meta Pets
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation
import SwiftUI

/// BackupManager handles the creation, saving, and restoration of app data backups.
class BackupManager {
    // MARK: - Singleton
    static let shared = BackupManager()
    
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let backupDirectoryName = "MetaPetsBackups"
    private let autoBackupLimit = 5 // Maximum number of auto-backups to keep
    
    // MARK: - Initialization
    private init() {
        createBackupDirectoryIfNeeded()
    }
    
    // MARK: - Backup Directory Management
    /// Creates the backup directory if it doesn't exist yet
    private func createBackupDirectoryIfNeeded() {
        guard let backupDirectoryURL = getBackupDirectoryURL() else {
            print("Failed to get documents directory")
            return
        }
        
        if !fileManager.fileExists(atPath: backupDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: backupDirectoryURL, withIntermediateDirectories: true)
                print("Created backup directory: \(backupDirectoryURL.path)")
            } catch {
                print("Failed to create backup directory: \(error)")
            }
        }
    }
    
    /// Returns the URL for the backup directory
    private func getBackupDirectoryURL() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        return documentsDirectory.appendingPathComponent(backupDirectoryName)
    }
    
    // MARK: - Backup Creation
    /// Creates a backup of the app data
    /// - Parameter viewModel: The PetViewModel containing pet data to backup
    /// - Returns: The backup data as a Data object
    func createBackup(viewModel: PetViewModel) async throws -> Data {
        // Create a simplified backup dictionary with just the pet data
        // You can expand this later as needed
        let backupData: [String: Any] = [
            "backupDate": Date(),
            "backupVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "petData": try await AppDataManager.shared.exportPetData()
        ]
        
        // Convert to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
        return jsonData
    }
    
    // MARK: - Auto Backup
    /// Saves an automatic backup of the app data
    /// - Parameter data: The backup data to save
    /// - Returns: The path where the backup was saved
    func saveAutoBackup(data: Data) throws -> String {
        guard let backupDir = getBackupDirectoryURL() else {
            throw BackupError.directoryCreationFailed
        }
        
        // Create a filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "MetaPets_AutoBackup_\(timestamp).json"
        
        // Save the backup
        let fileURL = backupDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        
        // Delete older auto-backups if we exceed the limit
        try cleanupOldAutoBackups()
        
        return fileURL.path
    }
    
    /// Creates a manual backup with a custom name
    /// - Parameters:
    ///   - data: The backup data
    ///   - name: Custom name for the backup file
    /// - Returns: The path where the backup was saved
    func saveManualBackup(data: Data, name: String) throws -> String {
        guard let backupDir = getBackupDirectoryURL() else {
            throw BackupError.directoryCreationFailed
        }
        
        // Create a safe filename
        let safeName = name.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        let filename = "MetaPets_\(safeName)_\(dateString).json"
        
        // Save the backup
        let fileURL = backupDir.appendingPathComponent(filename)
        try data.write(to: fileURL)
        
        return fileURL.path
    }
    
    /// Cleans up old auto-backups, keeping only the most recent ones
    private func cleanupOldAutoBackups() throws {
        guard let backupDir = getBackupDirectoryURL() else {
            throw BackupError.directoryCreationFailed
        }
        
        // Get all auto-backup files
        let autoBackupFiles = try fileManager.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: [.creationDateKey])
            .filter { $0.lastPathComponent.hasPrefix("MetaPets_AutoBackup_") }
        
        // Sort by creation date (newest first)
        let sortedFiles = try autoBackupFiles.sorted { file1, file2 in
            let date1 = try file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            let date2 = try file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
            return date1 > date2
        }
        
        // Delete older files if we have more than the limit
        if sortedFiles.count > autoBackupLimit {
            for file in sortedFiles[autoBackupLimit...] {
                try fileManager.removeItem(at: file)
                print("Deleted old auto-backup: \(file.lastPathComponent)")
            }
        }
    }
    
    // MARK: - Backup Listing
    /// Lists all available backups
    /// - Returns: Array of backup file metadata
    func listAllBackups() throws -> [BackupFile] {
        guard let backupDir = getBackupDirectoryURL() else {
            throw BackupError.directoryCreationFailed
        }
        
        // Get all backup files
        let backupFiles = try fileManager.contentsOfDirectory(at: backupDir, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])
            .filter { $0.pathExtension == "json" }
        
        // Create metadata for each file
        var backupMetadata = [BackupFile]()
        for fileURL in backupFiles {
            let isAutoBackup = fileURL.lastPathComponent.hasPrefix("MetaPets_AutoBackup_")
            let values = try fileURL.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
            let creationDate = values.creationDate ?? Date.distantPast
            let fileSize = values.fileSize ?? 0
            
            let backupFile = BackupFile(
                name: fileURL.lastPathComponent,
                path: fileURL.path,
                date: creationDate,
                size: fileSize,
                isAutoBackup: isAutoBackup
            )
            
            backupMetadata.append(backupFile)
        }
        
        // Sort by date, newest first
        return backupMetadata.sorted(by: { $0.date > $1.date })
    }
    
    // MARK: - Backup Restoration
    /// Restores data from a backup file
    /// - Parameters:
    ///   - url: URL to the backup file
    ///   - viewModel: The PetViewModel to update
    /// - Returns: A status message
    func restoreFromFile(url: URL, viewModel: PetViewModel) async throws -> String {
        // Read the backup file
        let backupData = try Data(contentsOf: url)
        
        // Parse the JSON
        guard let backupDict = try JSONSerialization.jsonObject(with: backupData) as? [String: Any] else {
            throw BackupError.invalidBackupFormat
        }
        
        // Extract the backup version
        let backupVersion = backupDict["backupVersion"] as? String ?? "1.0"
        print("Restoring backup from version \(backupVersion)")
        
        // Extract and restore pet data
        if let petData = backupDict["petData"] as? [String: Any] {
            // Use the AppDataManager to import the pet data
            try await AppDataManager.shared.importPetData(petData)
            
            // Reload the pet in the view model
            if let pet = AppDataManager.shared.loadPet() {
                await MainActor.run {
                    viewModel.updateWithNewPet(pet)
                }
            }
        } else {
            throw BackupError.petDataMissing
        }
        
        return "Backup restored successfully"
    }
    
    // MARK: - Share Backup
    /// Prepares a backup file for sharing
    /// - Parameter data: The backup data
    /// - Returns: A temporary URL to the backup file
    func prepareForSharing(data: Data) throws -> URL {
        // Create a temporary file for sharing
        let tempDir = fileManager.temporaryDirectory
        let fileName = "MetaPets_Backup_\(Date()).json"
        let tempFileURL = tempDir.appendingPathComponent(fileName)
        
        // Write the data to the temp file
        try data.write(to: tempFileURL)
        
        return tempFileURL
    }
}

// MARK: - Supporting Types
/// Represents a backup file with metadata
struct BackupFile: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let date: Date
    let size: Int
    let isAutoBackup: Bool
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedSize: String {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = [.useKB, .useMB]
        byteCountFormatter.countStyle = .file
        return byteCountFormatter.string(fromByteCount: Int64(size))
    }
}

/// Custom errors for backup operations
enum BackupError: Error, LocalizedError {
    case directoryCreationFailed
    case invalidBackupFormat
    case petDataMissing
    case restoreFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed:
            return "Failed to create backup directory"
        case .invalidBackupFormat:
            return "Invalid backup file format"
        case .petDataMissing:
            return "Pet data is missing in the backup"
        case .restoreFailed(let reason):
            return "Restore failed: \(reason)"
        }
    }
}

// Add these methods to AppDataManager in a separate extension
extension AppDataManager {
    /// Export pet data as a dictionary for backup
    func exportPetData() async throws -> [String: Any] {
        // Get the current pet
        guard let pet = loadPet() else {
            throw BackupError.petDataMissing
        }
        
        // Create a dictionary with pet data
        return [
            "pet": [
                "id": pet.id.uuidString,
                "name": pet.name,
                "type": pet.type.rawValue,
                "birthDate": pet.birthDate.timeIntervalSince1970
                // Add other pet properties as needed
            ],
            "settings": UserDefaults.standard.dictionaryRepresentation()
                .filter { key, _ in key.hasPrefix("MetaPets.") }
        ]
    }
    
    /// Import pet data from a backup
    func importPetData(_ data: [String: Any]) async throws {
        guard let petDict = data["pet"] as? [String: Any],
              let idString = petDict["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = petDict["name"] as? String,
              let typeRawValue = petDict["type"] as? String,
              let type = PetType(rawValue: typeRawValue),
              let birthTimeInterval = petDict["birthDate"] as? TimeInterval else {
            throw BackupError.petDataMissing
        }
        
        // Create a pet with the basic required properties
        let pet = Pet(
            id: id,
            name: name,
            type: type,
            birthDate: Date(timeIntervalSince1970: birthTimeInterval)
        )
        
        // Update the saved pet data
        // This uses a direct method for now
        UserDefaults.standard.set(try? JSONEncoder().encode(pet), forKey: "MetaPets.savedPet")
        
        // Restore settings if available
        if let settings = data["settings"] as? [String: Any] {
            for (key, value) in settings {
                if key.hasPrefix("MetaPets.") {
                    UserDefaults.standard.set(value, forKey: key)
                }
            }
        }
    }
} 