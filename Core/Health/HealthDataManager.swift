import Foundation
import HealthKit

struct HealthDataManager {
    private let healthStore = HKHealthStore()
    
    enum HealthDataType: String, CaseIterable {
        case steps = "steps"
        case activeEnergy = "active_energy"
        case carbs = "carbs"
        case proteins = "proteins"
        case fats = "fats"
        case calories = "calories"
    }
    
    struct DailyHealthData: Identifiable {
        let id = UUID()
        let date: Date
        let steps: Double
        let activeEnergy: Double
        let carbs: Double
        let proteins: Double
        let fats: Double
        let calories: Double
    }
    
    func requestAuthorization() async throws {
        let types: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!,
            HKObjectType.quantityType(forIdentifier: .dietaryProtein)!,
            HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!,
            HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        ]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            healthStore.requestAuthorization(toShare: [], read: types) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if !success {
                    continuation.resume(throwing: NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Authorization failed"]))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    func fetchHealthData(startDate: Date, endDate: Date) async throws -> [DailyHealthData] {
        let calendar = Calendar.current
        let dayCount = calendar.dateComponents([.day], from: calendar.startOfDay(for: startDate), to: calendar.startOfDay(for: endDate)).day ?? 0
        guard dayCount >= 0 else { return [] }
        
        var results: [DailyHealthData] = []
        for offset in 0...dayCount {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: startDate)) else { continue }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let steps = try await fetchSum(.stepCount, unit: .count(), start: day, end: nextDay)
            let activeEnergy = try await fetchSum(.activeEnergyBurned, unit: .kilocalorie(), start: day, end: nextDay)
            let carbs = try await fetchSum(.dietaryCarbohydrates, unit: .gram(), start: day, end: nextDay)
            let proteins = try await fetchSum(.dietaryProtein, unit: .gram(), start: day, end: nextDay)
            let fats = try await fetchSum(.dietaryFatTotal, unit: .gram(), start: day, end: nextDay)
            let calories = try await fetchSum(.dietaryEnergyConsumed, unit: .kilocalorie(), start: day, end: nextDay)
            results.append(DailyHealthData(date: day, steps: steps, activeEnergy: activeEnergy, carbs: carbs, proteins: proteins, fats: fats, calories: calories))
        }
        return results
    }
    
    private func fetchSum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async throws -> Double {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return 0 }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sum = stats?.sumQuantity() {
                    continuation.resume(returning: sum.doubleValue(for: unit))
                } else {
                    continuation.resume(returning: 0)
                }
            }
            healthStore.execute(query)
        }
    }
} 