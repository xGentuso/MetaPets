//
//  SettingsView.swift
//  Petopia
//
//  Created for Petopia
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var viewModel: PetViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingResetAlert = false
    @State private var showingTipsView = false
    @State private var showingBackupAlert = false
    @State private var backupMessage = ""
    @State private var isBackupSuccess = true
    @State private var showDocumentPicker = false
    @State private var cloudSyncEnabled = CloudKitManager.shared.isSyncEnabled
    @State private var showingCloudAlert = false
    @State private var cloudAlertMessage = ""
    @State private var isSyncing = false
    
    var body: some View {
        NavigationView {
            List {
                // Pet Section
                Section(header: Text("PET SETTINGS")) {
                    HStack {
                        Text("Pet Name")
                        Spacer()
                        Text(viewModel.pet.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Pet Type")
                        Spacer()
                        Text(viewModel.pet.type.rawValue.capitalized)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Pet Age")
                        Spacer()
                        Text("\(viewModel.pet.age) days")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Help Section
                Section(header: Text("HELP & INFORMATION")) {
                    Button(action: {
                        showingTipsView = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Tips & Tricks")
                        }
                    }
                    
                    Link(destination: URL(string: "https://example.com/petopia/help")!) {
                        HStack {
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                            Text("Online Help")
                        }
                    }
                }
                
                // Data Management Section
                Section(header: Text("DATA MANAGEMENT")) {
                    Toggle(isOn: $cloudSyncEnabled) {
                        HStack {
                            Image(systemName: "cloud")
                                .foregroundColor(.blue)
                            Text("iCloud Sync")
                        }
                    }
                    .onChange(of: cloudSyncEnabled) { newValue in
                        if newValue {
                            // Request CloudKit permissions when enabling
                            CloudKitManager.shared.requestPermissions { success in
                                if success {
                                    CloudKitManager.shared.isSyncEnabled = true
                                    showingCloudAlert = true
                                    cloudAlertMessage = "iCloud sync enabled. Your pet data will now sync across your devices."
                                } else {
                                    // Revert toggle if permissions not granted
                                    cloudSyncEnabled = false
                                    showingCloudAlert = true
                                    cloudAlertMessage = "Could not enable iCloud sync. Please make sure you are signed in to iCloud."
                                }
                            }
                        } else {
                            CloudKitManager.shared.isSyncEnabled = false
                        }
                    }
                    
                    Button(action: syncNow) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.blue)
                            Text("Sync Now")
                        }
                    }
                    .disabled(!cloudSyncEnabled)
                    
                    Button(action: createBackup) {
                        HStack {
                            Image(systemName: "arrow.up.doc")
                                .foregroundColor(.blue)
                            Text("Create Backup")
                        }
                    }
                    
                    Button(action: {
                        showDocumentPicker = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.down.doc")
                                .foregroundColor(.blue)
                            Text("Restore from Backup")
                        }
                    }
                    
                    Button(action: {
                        showingResetAlert = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                            Text("Reset All Data")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Development Section (Debug only)
                #if DEBUG
                Section(header: Text("DEVELOPMENT")) {
                    Button(action: {
                        // Reset onboarding
                        let onboardingViewModel = OnboardingViewModel()
                        onboardingViewModel.resetOnboarding()
                        
                        // Force app restart
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            exit(0)
                        }
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            Text("Reset Onboarding (Dev)")
                                .foregroundColor(.orange)
                        }
                    }
                }
                #endif
                
                // App Information Section
                Section(header: Text("ABOUT")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(getBuildNumber())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingResetAlert) {
                Alert(
                    title: Text("Reset All Data?"),
                    message: Text("This will delete all your pet data and achievements. This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        resetAllData()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showingTipsView) {
                TipsAndTricksView()
            }
            .fileExporter(
                isPresented: $showingBackupAlert,
                document: BackupDocument(data: AppDataManager.shared.exportData() ?? Data()),
                contentType: .json,
                defaultFilename: "petopia_backup_\(formattedCurrentDate())"
            ) { result in
                switch result {
                case .success(let url):
                    backupMessage = "Backup created successfully: \(url.lastPathComponent)"
                    isBackupSuccess = true
                case .failure(let error):
                    backupMessage = "Error creating backup: \(error.localizedDescription)"
                    isBackupSuccess = false
                }
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                do {
                    guard let selectedFile = try result.get().first else { return }
                    
                    // Gain access to the file
                    if selectedFile.startAccessingSecurityScopedResource() {
                        defer { selectedFile.stopAccessingSecurityScopedResource() }
                        
                        let success = DataMigrationHelper.shared.restoreFromBackup(fileURL: selectedFile)
                        backupMessage = success ?
                            "Your pet data has been successfully restored. The app will now restart." :
                            "There was a problem restoring the backup. Please try again with a different file."
                        isBackupSuccess = success
                        showingBackupAlert = true
                        
                        if success {
                            // Restart the app after successful restore
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                exit(0) // Force restart to load new data
                            }
                        }
                    }
                } catch {
                    backupMessage = "Error opening file: \(error.localizedDescription)"
                    isBackupSuccess = false
                    showingBackupAlert = true
                }
            }
            .alert(isPresented: $showingBackupAlert) {
                Alert(
                    title: Text(isBackupSuccess ? "Success" : "Error"),
                    message: Text(backupMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert(isPresented: $showingCloudAlert) {
                Alert(
                    title: Text("iCloud Sync"),
                    message: Text(cloudAlertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .overlay(
                Group {
                    if isSyncing {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                
                                Text("Syncing with iCloud...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(30)
                            .background(Color.gray.opacity(0.8))
                            .cornerRadius(15)
                        }
                    }
                }
            )
        }
    }
    
    // Create a backup of app data
    private func createBackup() {
        showingBackupAlert = true
    }
    
    // Reset all app data
    private func resetAllData() {
        // Create a backup before resetting
        _ = DataMigrationHelper.shared.createBackup()
        
        // Reset all data
        AppDataManager.shared.clearAllData()
        
        // Force app restart to initialize with fresh data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            exit(0) // This will force the app to restart
        }
    }
    
    // Get the build number
    private func getBuildNumber() -> String {
        if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return buildNumber
        }
        return "Unknown"
    }
    
    // Sync now functionality
    private func syncNow() {
        guard cloudSyncEnabled else { return }
        
        isSyncing = true
        
        // First upload data
        CloudKitManager.shared.uploadData()
        
        // Then download any newer data
        CloudKitManager.shared.downloadData { success in
            isSyncing = false
            
            showingCloudAlert = true
            cloudAlertMessage = success ?
                "Sync completed successfully. Your data is now up to date across all your devices." :
                "There was a problem syncing your data. Please try again later."
            
            // If sync was successful and new data was downloaded
            if success {
                // Refresh the pet view model with new data
                if let newPet = AppDataManager.shared.loadPet() {
                    viewModel.pet = newPet
                }
            }
        }
    }
    
    // Format current date for filename
    private func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// Document type for backup file exports
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            self.data = Data()
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
