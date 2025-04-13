//
//  CurrencyManager.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import Foundation

enum CurrencyTransactionType: String, Codable {
    case earned
    case spent
}

struct CurrencyTransaction: Identifiable, Codable {
    var id = UUID()
    var amount: Int
    var description: String
    var type: CurrencyTransactionType
    var date: Date
    
    var isEarned: Bool {
        return type == .earned
    }
}

class CurrencyManager {
    static let shared = CurrencyManager()
    
    // Transaction history
    private(set) var transactions: [CurrencyTransaction] = []
    
    // Maximum number of transactions to keep in history
    private let maxTransactionHistory = 100
    
    private init() {
        loadTransactions()
    }
    
    // Add currency with a description of how it was earned
    func addCurrency(to pet: inout Pet, amount: Int, description: String) {
        guard amount > 0 else { return }
        
        pet.currency += amount
        
        let transaction = CurrencyTransaction(
            amount: amount,
            description: description,
            type: .earned,
            date: Date()
        )
        
        addTransaction(transaction)
    }
    
    // Spend currency with a description of what it was spent on
    func spendCurrency(from pet: inout Pet, amount: Int, description: String) -> Bool {
        guard amount > 0 else { return false }
        
        // Check if pet has enough currency
        guard pet.currency >= amount else { return false }
        
        pet.currency -= amount
        
        let transaction = CurrencyTransaction(
            amount: amount,
            description: description,
            type: .spent,
            date: Date()
        )
        
        addTransaction(transaction)
        
        return true
    }
    
    // Add transaction and maintain history size
    private func addTransaction(_ transaction: CurrencyTransaction) {
        transactions.append(transaction)
        
        // Limit transaction history size
        if transactions.count > maxTransactionHistory {
            transactions = Array(transactions.suffix(maxTransactionHistory))
        }
        
        saveTransactions()
    }
    
    // Get daily bonus amount based on streak
    func getDailyBonusAmount(streak: Int) -> Int {
        // Base amount plus bonus for streak
        return 10 + min(streak * 5, 50)
    }
    
    // Save transaction history
    private func saveTransactions() {
        if let encoded = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(encoded, forKey: "CurrencyTransactions")
        }
    }
    
    // Load transaction history
    private func loadTransactions() {
        if let savedData = UserDefaults.standard.data(forKey: "CurrencyTransactions"),
           let loadedTransactions = try? JSONDecoder().decode([CurrencyTransaction].self, from: savedData) {
            transactions = loadedTransactions
        }
    }
    
    // Clear transaction history (for testing or resetting)
    func clearTransactions() {
        transactions = []
        saveTransactions()
    }
}
