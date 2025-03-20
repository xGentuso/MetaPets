//
//  StoreTabView.swift
//  Petopia
//
//  Created for Petopia
//

import SwiftUI

struct StoreTabView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var selection = 0
    @State private var showingDailyBonus = false
    @State private var bonusAmount = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Currency display that's always visible
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                    
                    Text("\(viewModel.pet.currency) Coins")
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.1))
                
                Picker("Store Type", selection: $selection) {
                    Text("Shop").tag(0)
                    Text("Currency").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                if selection == 0 {
                    // Regular store view
                    StoreContentView(viewModel: viewModel)
                } else {
                    // Currency management
                    CurrencyContentView(viewModel: viewModel, showingDailyBonus: $showingDailyBonus, bonusAmount: $bonusAmount)
                }
            }
            .navigationTitle("Store")
            .alert(isPresented: $showingDailyBonus) {
                Alert(
                    title: Text("Daily Bonus!"),
                    message: Text("You received \(bonusAmount) coins for your daily login!\nCurrent streak: \(viewModel.dailyBonusStreak) day\(viewModel.dailyBonusStreak == 1 ? "" : "s")"),
                    dismissButton: .default(Text("Awesome!"))
                )
            }
        }
    }
}

// Extract store content to avoid nesting NavigationViews
struct StoreContentView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var selectedTab = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var insufficientFunds = false
    
    var body: some View {
        VStack {
            Picker("Store Section", selection: $selectedTab) {
                Text("Medicine").tag(0)
                Text("Accessories").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == 0 {
                List(viewModel.availableMedicine) { medicine in
                    Button(action: {
                        if viewModel.buyMedicine(medicine: medicine) {
                            viewModel.heal(medicine: medicine)
                            alertMessage = "Successfully purchased \(medicine.name)"
                            insufficientFunds = false
                        } else {
                            alertMessage = "Not enough coins to purchase \(medicine.name)"
                            insufficientFunds = true
                        }
                        showingAlert = true
                    }) {
                        HStack {
                            Image(systemName: "cross.case")
                                .foregroundColor(.red)
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading) {
                                Text(medicine.name)
                                    .font(.headline)
                                Text("Health: +\(Int(medicine.healthValue))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(medicine.price) coins")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                List(viewModel.availableAccessories) { accessory in
                    Button(action: {
                        if viewModel.pet.level >= accessory.unlockLevel {
                            if viewModel.buyAccessory(accessory: accessory) {
                                alertMessage = "Successfully purchased \(accessory.name)"
                                insufficientFunds = false
                            } else {
                                alertMessage = "Not enough coins to purchase \(accessory.name)"
                                insufficientFunds = true
                            }
                            showingAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "gift")
                                .foregroundColor(.purple)
                                .frame(width: 30, height: 30)
                            
                            VStack(alignment: .leading) {
                                Text(accessory.name)
                                    .font(.headline)
                                Text("Position: \(accessory.position.rawValue.capitalized)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if viewModel.pet.level >= accessory.unlockLevel {
                                Text("\(accessory.price) coins")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            } else {
                                Text("Unlock at level \(accessory.unlockLevel)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .disabled(viewModel.pet.level < accessory.unlockLevel)
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(insufficientFunds ? "Insufficient Funds" : "Purchase Successful"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    insufficientFunds = false
                }
            )
        }
    }
}

// Extract currency view content
struct CurrencyContentView: View {
    @ObservedObject var viewModel: PetViewModel
    @Binding var showingDailyBonus: Bool
    @Binding var bonusAmount: Int
    
    var body: some View {
        VStack {
            // Daily bonus button
            Button(action: {
                let amount = viewModel.claimDailyBonus()
                if amount > 0 {
                    bonusAmount = amount
                    showingDailyBonus = true
                }
            }) {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.white)
                    
                    Text("Claim Daily Bonus")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(canClaimDailyBonus ? Color.blue : Color.gray)
                )
            }
            .disabled(!canClaimDailyBonus)
            .padding()
            
            Text("Streak: \(viewModel.dailyBonusStreak) day\(viewModel.dailyBonusStreak == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Divider()
            
            // Transaction history
            Text("Transaction History")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top)
            
            List {
                ForEach(viewModel.getTransactionHistory().sorted(by: { $0.date > $1.date })) { transaction in
                    HStack {
                        Image(systemName: transaction.isEarned ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                            .foregroundColor(transaction.isEarned ? .green : .red)
                        
                        VStack(alignment: .leading) {
                            Text(transaction.description)
                                .font(.headline)
                            
                            Text(formatDate(transaction.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(transaction.isEarned ? "+" : "-")\(transaction.amount)")
                            .fontWeight(.bold)
                            .foregroundColor(transaction.isEarned ? .green : .red)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var canClaimDailyBonus: Bool {
        guard let lastClaimDate = viewModel.lastDailyBonusDate else {
            return true
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastClaim = Calendar.current.startOfDay(for: lastClaimDate)
        
        return today != lastClaim
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct StoreTabView_Previews: PreviewProvider {
    static var previews: some View {
        StoreTabView(viewModel: PetViewModel())
    }
}
