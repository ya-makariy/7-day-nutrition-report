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
        
        // Очищаем старые CSV файлы
        cleanupOldCSVFiles()
        
        let header = "Date,Steps,Active Energy (kcal),Carbs (g),Proteins (g),Fats (g),Calories (kcal)\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let rows = dailyData.map { data in
            "\(formatter.string(from: data.date)),\(Int(data.steps)),\(Int(data.activeEnergy)),\(String(format: "%.1f", data.carbs)),\(String(format: "%.1f", data.proteins)),\(String(format: "%.1f", data.fats)),\(Int(data.calories))"
        }
        let csvString = header + rows.joined(separator: "\n")
        
        do {
            // Используем Documents директорию вместо временной
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "HealthStats_\(Date().timeIntervalSince1970).csv"
            var url = documentsPath.appendingPathComponent(fileName)
            
            // Записываем файл
            try csvString.write(to: url, atomically: true, encoding: .utf8)
            
            // Устанавливаем правильные атрибуты файла
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
            
            self.csvURL = url
        } catch {
            self.error = "Failed to export CSV: \(error.localizedDescription)"
        }
    }
    
    private func cleanupOldCSVFiles() {
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let contents = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            
            // Удаляем старые CSV файлы (старше 1 часа)
            let oneHourAgo = Date().addingTimeInterval(-3600)
            for url in contents {
                if url.pathExtension == "csv" && url.lastPathComponent.hasPrefix("HealthStats_") {
                    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                    if let creationDate = attributes[.creationDate] as? Date, creationDate < oneHourAgo {
                        try FileManager.default.removeItem(at: url)
                    }
                }
            }
        } catch {
            // Игнорируем ошибки очистки
            print("Failed to cleanup old CSV files: \(error)")
        }
    }
} 