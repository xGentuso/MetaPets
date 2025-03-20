//
//  CurrencyView.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct CurrencyView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var showingDailyBonus = false
    @State private var bonusAmount = 0
    
    var body: some View {
        NavigationView {
            VStack {
                // Currency display
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.yellow)
                    
                    Text("\(viewModel.pet.currency) Coins")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.2))
                )
                .padding(.vertical)
                
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
                .padding(.horizontal)
                
                Text("Streak: \(viewModel.dailyBonusStreak) day\(viewModel.dailyBonusStreak == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
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
            .navigationTitle("Currency")
            .alert(isPresented: $showingDailyBonus) {
                Alert(
                    title: Text("Daily Bonus!"),
                    message: Text("You received \(bonusAmount) coins for your daily login!\nCurrent streak: \(viewModel.dailyBonusStreak) day\(viewModel.dailyBonusStreak == 1 ? "" : "s")"),
                    dismissButton: .default(Text("Awesome!"))
                )
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

struct CurrencyView_Previews: PreviewProvider {
    static var previews: some View {
        CurrencyView(viewModel: PetViewModel())
    }
}
