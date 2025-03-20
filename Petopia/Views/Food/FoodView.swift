//
//  FoodView.swift
//  Petopia
//
//  Created by ryan mota on 2025-03-20.
//

import SwiftUI

struct FoodView: View {
    @ObservedObject var viewModel: PetViewModel
    
    var body: some View {
        NavigationView {
            List(viewModel.availableFood) { food in
                Button(action: {
                    viewModel.feed(food: food)
                }) {
                    HStack {
                        Image(systemName: "fork.knife")
                            .foregroundColor(.orange)
                            .frame(width: 30, height: 30)
                        
                        VStack(alignment: .leading) {
                            Text(food.name)
                                .font(.headline)
                            Text("Nutrition: +\(Int(food.nutritionValue)) • Health: +\(Int(food.healthValue))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(food.price) coins")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Feed \(viewModel.pet.name)")
        }
    }
}

struct FoodView_Previews: PreviewProvider {
    static var previews: some View {
        FoodView(viewModel: PetViewModel())
    }
}
