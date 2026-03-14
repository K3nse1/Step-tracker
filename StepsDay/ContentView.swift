//
//  ContentView.swift
//  StepsDay
//
//  Created by Raúl Santos Gutiérrez on 14/3/26.
//

import SwiftUI

struct ContentView: View {
    @State private var steps: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            
            Text("Pasos hoy")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("\(Int(steps))")
                .font(.system(size: 64, weight: .bold, design: .rounded))
            
        }
        .onAppear {
            HealthKitManager.shared.requestAuthorization { success in
                guard success else { return }
                HealthKitManager.shared.fetchTodaySteps { count in
                    DispatchQueue.main.async {
                        steps = count
                    }
                }
            }
        }
    }
}
