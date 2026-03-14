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
// Le dice al sistema cuándo y con qué datos actualizar el widget
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
        let defaults = UserDefaults(suiteName: "group.com.rsantosg.stepsday")
        let cached = defaults?.double(forKey: "todaySteps") ?? 0
        print("🔵 Widget leyendo App Group: \(cached)")
        
        HealthKitManager.shared.requestAuthorization { success in
            print(success ? "🔵 Widget autorización OK" : "🔴 Widget sin autorización")
            guard success else {
                completion(cached)
                return
            }
            HealthKitManager.shared.fetchTodaySteps { steps in
                print("🔵 Widget pasos de HealthKit: \(steps)")
                completion(steps)
            }
        }
    }
} // cierra Provider

// MARK: - Entry
// El modelo de datos del widget: una fecha y un número de pasos
struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Double
}

// MARK: - Widget View
// El diseño visual del widget
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
