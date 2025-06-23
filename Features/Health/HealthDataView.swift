import SwiftUI

extension String {
    var localized: String { NSLocalizedString(self, comment: "") }
}

struct HealthDataView: View {
    @StateObject private var viewModel = HealthDataViewModel()
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Start Date".localized, selection: $startDate, displayedComponents: .date)
                DatePicker("End Date".localized, selection: $endDate, displayedComponents: .date)
                Button("Fetch Data".localized) {
                    Task { await viewModel.fetchData(startDate: startDate, endDate: endDate) }
                }
                .padding()
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    Text(error).foregroundColor(.red)
                } else {
                    List(viewModel.dailyData) { data in
                        VStack(alignment: .leading) {
                            Text(data.date, style: .date)
                            Text("\("Steps".localized): \(Int(data.steps))")
                            Text("\("Active Energy".localized): \(Int(data.activeEnergy)) kcal")
                            Text("\("Carbs".localized): \(data.carbs, specifier: "%.1f") g")
                            Text("\("Proteins".localized): \(data.proteins, specifier: "%.1f") g")
                            Text("\("Fats".localized): \(data.fats, specifier: "%.1f") g")
                            Text("\("Calories".localized): \(Int(data.calories)) kcal")
                        }
                    }
                }
                Button("Export CSV".localized) {
                    viewModel.exportCSV()
                }
                .padding()
                .disabled(viewModel.dailyData.isEmpty)
                .sheet(isPresented: $showShareSheet) {
                    if let url = viewModel.csvURL {
                        ShareSheet(activityItems: [url])
                    }
                }
            }
            .navigationTitle("Health Stats".localized)
            .onAppear {
                Task { await viewModel.requestAuthorization() }
            }
            .onChange(of: viewModel.csvURL) { _ in
                showShareSheet = viewModel.csvURL != nil
            }
        }
    }
} 