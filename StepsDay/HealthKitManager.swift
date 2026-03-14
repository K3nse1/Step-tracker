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
    
    // Pide permiso al usuario para leer los pasos
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let stepType = HKQuantityType(.stepCount)
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, _ in
            completion(success)
        }
    }
    
    // Lee los pasos de hoy
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
            completion(steps)
        }
        
        healthStore.execute(query)
    }
}
