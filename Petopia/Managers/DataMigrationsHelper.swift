//
//  DataMigrationHelper.swift
//  Petopia
//
//  Created for Petopia data migration
//

import Foundation

class DataMigrationHelper {
    static let shared = DataMigrationHelper()
    
    private let currentSchemaVersionKey = "CurrentDataSchemaVersion"
    private let currentSchemaVersion = 1  // Increment this when data schema changes
    
    private init() {}
    
    // Call this at app startup to perform any necessary migrations
    func performMigrationsIfNeeded() {
        let savedVersion = UserDefaults.standard.integer(forKey: currentSchemaVersionKey)
        
        if savedVersion < currentSchemaVersion {
            migrateFromVersion(savedVersion, toVersion: currentSchemaVersion)
            UserDefaults.standard.set(currentSchemaVersion, forKey: currentSchemaVersionKey)
        }
    }
    
    private func migrateFromVersion(_ oldVersion: Int, toVersion newVersion: Int) {
        print("Migrating data from schema version \(oldVersion) to \(newVersion)")
        
        // Version 0 to 1: Initial migration if needed
        if oldVersion < 1 {
            migrateToVersion1()
        }
        
        // Future migrations would be added here
        // if oldVersion < 2 { migrateToVersion2() }
        // if oldVersion < 3 { migrateToVersion3() }
    }
    
    // Migration to version 1: Set up onboarding flag for existing users
    private func migrateToVersion1() {
        #if DEBUG
        // Skip setting onboarding complete in debug mode to allow testing
        print("Debug mode: Skipping automatic onboarding completion for existing pets")
        #else
        // If user already has a pet, they should skip onboarding
        if AppDataManager.shared.loadPet() != nil {
            AppDataManager.shared.setOnboardingComplete(true)
            print("Migration: Marked onboarding as complete for existing user")
        }
        #endif
    }
    
    // MARK: - Backup & Restore
    
    // Create a backup of all app data
    func createBackup() -> URL? {
        guard let data = AppDataManager.shared.exportData() else {
            print("Failed to export data for backup")
            return nil
        }
        
        // Create a temporary file
        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let backupFileURL = temporaryDirectoryURL.appendingPathComponent("petopia_backup_\(Date().timeIntervalSince1970).json")
        
        do {
            try data.write(to: backupFileURL)
            return backupFileURL
        } catch {
            print("Failed to write backup file: \(error)")
            return nil
        }
    }
    
    // Restore from a backup file
    func restoreFromBackup(fileURL: URL) -> Bool {
        do {
            let data = try Data(contentsOf: fileURL)
            return AppDataManager.shared.importData(jsonData: data)
        } catch {
            print("Failed to read backup file: \(error)")
            return false
        }
    }
}
