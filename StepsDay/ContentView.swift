import SwiftUI
import WidgetKit
import Combine

struct ContentView: View {
    @State private var steps: Double = 0
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
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
            actualizarPasos()
        }
        .onReceive(timer) { _ in
            actualizarPasos()
        }
    }
    
    func actualizarPasos() {
        HealthKitManager.shared.requestAuthorization { success in
            guard success else { return }
            HealthKitManager.shared.fetchTodaySteps { count in
                DispatchQueue.main.async {
                    steps = count
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
        }
    }
}
