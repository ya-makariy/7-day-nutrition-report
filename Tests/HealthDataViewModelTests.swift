import XCTest
@testable import SevenDayNutritionReportApp

@MainActor
final class HealthDataViewModelTests: XCTestCase {
    func testExportCSV_GeneratesCorrectCSV() {
        let viewModel = HealthDataViewModel()
        let date = Date(timeIntervalSince1970: 0)
        viewModel.dailyData = [
            HealthDataManager.DailyHealthData(date: date, steps: 1000, activeEnergy: 200, carbs: 50, proteins: 20, fats: 10, calories: 500)
        ]
        viewModel.exportCSV()
        guard let url = viewModel.csvURL else {
            XCTFail("CSV URL should not be nil")
            return
        }
        let csv = try? String(contentsOf: url)
        XCTAssertNotNil(csv)
        XCTAssertTrue(csv!.contains("1000"))
        XCTAssertTrue(csv!.contains("200"))
        XCTAssertTrue(csv!.contains("50.0"))
        XCTAssertTrue(csv!.contains("20.0"))
        XCTAssertTrue(csv!.contains("10.0"))
        XCTAssertTrue(csv!.contains("500"))
    }
    
    func testEmptyData_ExportCSVDoesNotCrash() {
        let viewModel = HealthDataViewModel()
        viewModel.dailyData = []
        viewModel.exportCSV()
        XCTAssertNil(viewModel.csvURL)
    }
} 