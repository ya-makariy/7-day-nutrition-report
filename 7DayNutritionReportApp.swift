import SwiftUI

@main
struct SevenDayNutritionReportApp: App {
    var body: some Scene {
        WindowGroup {
            HealthDataView()
                .preferredColorScheme(.none) // Поддержка светлой/темной темы
        }
        .windowResizability(.contentSize)
    }
} 
