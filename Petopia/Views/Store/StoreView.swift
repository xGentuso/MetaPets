//
//  StoreView.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

//
//  StoreView.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct StoreView: View {
    @ObservedObject var viewModel: PetViewModel
    @State private var selectedTab = 0
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var insufficientFunds = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Currency display
                HStack {
                    Spacer()
                    CurrencyBadge(amount: viewModel.pet.currency)
                }
                .padding(.horizontal)
                
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
            .navigationTitle("Store")
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
}

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView(viewModel: PetViewModel())
    }
}
