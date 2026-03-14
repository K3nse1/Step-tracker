//
//  HealthKitManager.swift
//  StepsDay
//
//  Created by Raúl Santos Gutiérrez on 14/3/26.
//

import Foundation
import HealthKit

class HealthKitManager {
    
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    private let appGroupID = "group.com.rsantosg.stepsday"
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("❌ HealthKit no disponible")
            completion(false)
            return
        }
        
        let stepType = HKQuantityType(.stepCount)
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            print(success ? "✅ Autorización concedida" : "❌ Autorización denegada: \(String(describing: error))")
            completion(success)
        }
    }
    
    func fetchTodaySteps(completion: @escaping (Double) -> Void) {
        let stepType = HKQuantityType(.stepCount)
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: Date(),
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            print("✅ Pasos obtenidos: \(steps)")
            
            let defaults = UserDefaults(suiteName: self.appGroupID)
            defaults?.set(steps, forKey: "todaySteps")
            defaults?.synchronize()
            
            let verificacion = defaults?.double(forKey: "todaySteps") ?? -1
            print("✅ Verificación App Group: \(verificacion)")
            
            completion(steps)
        }
        
        healthStore.execute(query)
    }
}
