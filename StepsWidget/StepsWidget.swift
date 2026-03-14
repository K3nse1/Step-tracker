//
//  StepsWidget.swift
//  StepsWidget
//
//  Created by Raúl Santos Gutiérrez on 14/3/26.
//

import WidgetKit
import SwiftUI
import HealthKit

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> StepsEntry {
        StepsEntry(date: Date(), steps: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        fetchSteps { steps in
            completion(StepsEntry(date: Date(), steps: steps))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        fetchSteps { steps in
            let entry = StepsEntry(date: Date(), steps: steps)
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    private func fetchSteps(completion: @escaping (Double) -> Void) {
        // Leemos del App Group — la app principal es quien pide autorización
        let defaults = UserDefaults(suiteName: "group.com.rsantosg.stepsday")
        let cached = defaults?.double(forKey: "todaySteps") ?? 0
        print("🔵 Widget leyendo App Group: \(cached)")
        
        // Intentamos actualizar desde HealthKit directamente sin pedir autorización
        let stepType = HKQuantityType(.stepCount)
        let healthStore = HKHealthStore()
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
        ) { _, result, error in
            if let steps = result?.sumQuantity()?.doubleValue(for: .count()) {
                print("🔵 Widget pasos de HealthKit: \(steps)")
                defaults?.set(steps, forKey: "todaySteps")
                defaults?.synchronize()
                completion(steps)
            } else {
                print("🔵 Widget usando caché: \(cached)")
                completion(cached)
            }
        }
        
        healthStore.execute(query)
    }
} // cierra Provider

// MARK: - Entry
struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Double
}

// MARK: - Widget View
struct PasosDiaWidgetEntryView: View {
    var entry: StepsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 2) {
                Image(systemName: "figure.walk")
                Text("\(Int(entry.steps))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .containerBackground(.fill.tertiary, for: .widget)
        case .accessoryRectangular:
            HStack {
                Image(systemName: "figure.walk")
                VStack(alignment: .leading) {
                    Text("Pasos hoy")
                        .font(.caption)
                    Text("\(Int(entry.steps))")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
            .containerBackground(.fill.tertiary, for: .widget)
        default:
            VStack(spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 28))
                    .foregroundStyle(.green)
                Text("Pasos hoy")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(Int(entry.steps))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }
            .containerBackground(.fill.tertiary, for: .widget)
        }
    }
} // cierra PasosDiaWidgetEntryView

// MARK: - Widget Configuration
struct StepsWidget: Widget {
    let kind: String = "StepsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PasosDiaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Pasos del día")
        .description("Muestra los pasos que llevas hoy.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
} // cierra StepsWidget
