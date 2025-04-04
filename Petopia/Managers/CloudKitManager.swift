//
//  CloudKitManager.swift
//  Petopia
//
//  Created for Petopia cloud sync
//

import Foundation
import CloudKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let petRecordType = "PetData"
    private let achievementsRecordType = "Achievements"
    private let currencyRecordType = "Currency"
    
    private let syncEnabledKey = "CloudSyncEnabled"
    
    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }
    
    // Check if cloud sync is enabled
    var isSyncEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: syncEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: syncEnabledKey)
            if newValue {
                // Initial sync when enabling
                uploadData()
            }
        }
    }
    
    // Request permission to use CloudKit
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    // User is logged in to iCloud
                    completion(true)
                case .noAccount, .restricted, .couldNotDetermine:
                    // User is not logged in to iCloud or restricted
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }
    
    // Upload pet data to CloudKit
    func uploadData() {
        guard isSyncEnabled else { return }
        
        // Check iCloud status before proceeding
        container.accountStatus { [weak self] status, error in
            guard let self = self, status == .available else { return }
            
            DispatchQueue.main.async {
                self.uploadPetData()
                self.uploadAchievementsData()
                self.uploadCurrencyData()
            }
        }
    }
    
    // Download pet data from CloudKit
    func downloadData(completion: @escaping (Bool) -> Void) {
        guard isSyncEnabled else {
            completion(false)
            return
        }
        
        // Check iCloud status before proceeding
        container.accountStatus { [weak self] status, error in
            guard let self = self, status == .available else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // Download all data types
            let dispatchGroup = DispatchGroup()
            
            dispatchGroup.enter()
            self.downloadPetData { _ in
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            self.downloadAchievementsData { _ in
                dispatchGroup.leave()
            }
            
            dispatchGroup.enter()
            self.downloadCurrencyData { _ in
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(true)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func uploadPetData() {
        // Get pet data
        guard let pet = AppDataManager.shared.loadPet(),
              let petData = try? JSONEncoder().encode(pet) else {
            print("No pet data to upload")
            return
        }
        
        // Create record
        let record = CKRecord(recordType: petRecordType)
        record["petData"] = petData
        record["lastModified"] = Date()
        
        // Save record
        privateDatabase.save(record) { _, error in
            if let error = error {
                print("Error uploading pet data: \(error.localizedDescription)")
            } else {
                print("Pet data uploaded successfully")
            }
        }
    }
    
    private func uploadAchievementsData() {
        // This would be expanded to actually save achievements data
        // For now, we'll just log a placeholder message
        print("Achievement data upload would happen here")
    }
    
    private func uploadCurrencyData() {
        // This would be expanded to actually save currency data
        // For now, we'll just log a placeholder message
        print("Currency data upload would happen here")
    }
    
    private func downloadPetData(completion: @escaping (Bool) -> Void) {
        let query = CKQuery(recordType: petRecordType, predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error downloading pet data: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let record = records?.first,
                      let petData = record["petData"] as? Data,
                      let pet = try? JSONDecoder().decode(Pet.self, from: petData) else {
                    completion(false)
                    return
                }
                
                // Save the downloaded pet
                if let encoded = try? JSONEncoder().encode(pet) {
                    UserDefaults.standard.set(encoded, forKey: "SavedPet")
                    print("Pet data downloaded and saved successfully")
                    completion(true)
                } else {
                    completion(false)
                }
            }
        }
    }
    
    private func downloadAchievementsData(completion: @escaping (Bool) -> Void) {
        // This would be expanded to actually download achievements data
        // For now, we'll just log a placeholder message and call completion
        print("Achievement data download would happen here")
        completion(true)
    }
    
    private func downloadCurrencyData(completion: @escaping (Bool) -> Void) {
        // This would be expanded to actually download currency data
        // For now, we'll just log a placeholder message and call completion
        print("Currency data download would happen here")
        completion(true)
    }
}
