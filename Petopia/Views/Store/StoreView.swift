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
    
    var body: some View {
        NavigationView {
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
                            viewModel.heal(medicine: medicine)
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
                            viewModel.addAccessory(accessory)
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
        }
    }
}

struct StoreView_Previews: PreviewProvider {
    static var previews: some View {
        StoreView(viewModel: PetViewModel())
    }
}
