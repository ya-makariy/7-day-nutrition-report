import Foundation
import Combine

@MainActor
final class HealthDataViewModel: ObservableObject {
    @Published var dailyData: [HealthDataManager.DailyHealthData] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var csvURL: URL?
    @Published var noDataErrorShouldHide: Bool = false
    
    private let manager = HealthDataManager()
    
    func requestAuthorization() async {
        do {
            try await manager.requestAuthorization()
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func fetchData(startDate: Date, endDate: Date) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let data = try await manager.fetchHealthData(startDate: startDate, endDate: endDate)
            self.dailyData = data
        } catch {
            self.error = error.localizedDescription
        }
    }
    
    func exportCSV() {
        guard !dailyData.isEmpty else { return }
        let header = "Date,Steps,Active Energy (kcal),Carbs (g),Proteins (g),Fats (g),Calories (kcal)\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let rows = dailyData.map { data in
            "\(formatter.string(from: data.date)),\(Int(data.steps)),\(Int(data.activeEnergy)),\(String(format: "%.1f", data.carbs)),\(String(format: "%.1f", data.proteins)),\(String(format: "%.1f", data.fats)),\(Int(data.calories))"
        }
        let csvString = header + rows.joined(separator: "\n")
        do {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("HealthStats.csv")
            try csvString.write(to: url, atomically: true, encoding: .utf8)
            self.csvURL = url
        } catch {
            self.error = "Failed to export CSV: \(error.localizedDescription)"
        }
    }
} 