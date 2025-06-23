import SwiftUI
import Charts

extension String {
    var localized: String { NSLocalizedString(self, comment: "") }
}

struct HealthDataView: View {
    @StateObject private var viewModel = HealthDataViewModel()
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showShareSheet = false
    @State private var selectedTab = 0
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Верхняя часть - прокручиваемый контент
                ScrollView {
                    VStack(spacing: 16) {
                        // Date Selection Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Date Range".localized)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Start Date".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button(action: { showStartDatePicker = true }) {
                                        Text(dateString(startDate))
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(8)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(8)
                                    }
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("End Date".localized)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button(action: { showEndDatePicker = true }) {
                                        Text(dateString(endDate))
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(8)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Fetch Data Button
                        Button(action: {
                            Task { await viewModel.fetchData(startDate: startDate, endDate: endDate) }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.title2)
                                }
                                Text(viewModel.isLoading ? "Loading...".localized : "Fetch Data".localized)
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isLoading ? Color.gray : Color.blue)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal)
                        
                        // Error Display
                        if let error = viewModel.error, !viewModel.noDataErrorShouldHide {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        
                        // Content based on selected tab
                        if !viewModel.dailyData.isEmpty {
                            if selectedTab == 0 {
                                // Daily Data Content
                                DailyDataContent(data: viewModel.dailyData, onExport: {
                                    viewModel.exportCSV()
                                })
                            } else {
                                // Charts Content
                                ChartsContent(data: viewModel.dailyData)
                            }
                        } else if !viewModel.isLoading && viewModel.error == nil {
                            // Empty State
                            VStack(spacing: 16) {
                                Image(systemName: "heart.text.square")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("No Data Available".localized)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                Text("Select a date range and tap 'Fetch Data' to get started.".localized)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 40)
                        }
                        
                        Spacer(minLength: 120)
                    }
                }
                
                if !viewModel.dailyData.isEmpty {
                    Divider()
                    HStack {
                        Button(action: { selectedTab = 0 }) {
                            VStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.title2)
                                Text("Daily Data".localized)
                                    .font(.caption)
                            }
                            .foregroundColor(selectedTab == 0 ? .blue : .secondary)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: { selectedTab = 1 }) {
                            VStack(spacing: 4) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.title2)
                                Text("Charts".localized)
                                    .font(.caption)
                            }
                            .foregroundColor(selectedTab == 1 ? .blue : .secondary)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                }
            }
            .ignoresSafeArea(.container, edges: .bottom)
            .navigationTitle("Health Stats".localized)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task { await viewModel.requestAuthorization() }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = viewModel.csvURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .sheet(isPresented: $showStartDatePicker) {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { startDate },
                        set: { newValue in
                            startDate = newValue
                            if endDate < newValue { endDate = newValue }
                            viewModel.error = nil
                            viewModel.noDataErrorShouldHide = true
                            showStartDatePicker = false
                        }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .presentationDetents([.medium])
                .padding()
            }
            .sheet(isPresented: $showEndDatePicker) {
                DatePicker(
                    "",
                    selection: Binding(
                        get: { endDate },
                        set: { newValue in
                            endDate = newValue
                            if startDate > newValue { startDate = newValue }
                            viewModel.error = nil
                            viewModel.noDataErrorShouldHide = true
                            showEndDatePicker = false
                        }
                    ),
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .presentationDetents([.medium])
                .padding()
            }
            .onChange(of: startDate) { _ in
                viewModel.error = nil
                viewModel.noDataErrorShouldHide = true
            }
            .onChange(of: endDate) { _ in
                viewModel.error = nil
                viewModel.noDataErrorShouldHide = true
            }
            .onChange(of: viewModel.isLoading) { isLoading in
                if isLoading {
                    viewModel.noDataErrorShouldHide = false
                }
            }
            .onChange(of: selectedTab) { _ in
                viewModel.error = nil
                viewModel.noDataErrorShouldHide = true
            }
            .onChange(of: viewModel.csvURL) { _ in
                showShareSheet = viewModel.csvURL != nil
            }
        }
    }
    
    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
 
struct DailyDataContent: View {
    let data: [HealthDataManager.DailyHealthData]
    let onExport: () -> Void
    @State private var selectedDayIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with Export Button
            HStack {
                Text("Daily Data".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button("Export CSV".localized) {
                    onExport()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal)
            
            // Smart page control для дней (максимум 7 точек)
            if data.count > 1 {
                SmartPageControl(
                    currentIndex: selectedDayIndex,
                    totalPages: data.count,
                    maxVisibleDots: 7,
                    onIndexChanged: { newIndex in
                        selectedDayIndex = newIndex
                    }
                )
                .padding(.horizontal)
            }
            
            // Горизонтальный скролл по дням (без заголовка даты)
            TabView(selection: $selectedDayIndex) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, dailyData in
                    VStack(spacing: 16) {
                        DailyDataCard(data: dailyData)
                    }
                    .padding(.horizontal)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 380)
        }
    }
}

struct SmartPageControl: View {
    let currentIndex: Int
    let totalPages: Int
    let maxVisibleDots: Int
    let onIndexChanged: (Int) -> Void
    
    private var visibleRange: Range<Int> {
        let halfVisible = maxVisibleDots / 2
        let start = max(0, min(currentIndex - halfVisible, totalPages - maxVisibleDots))
        let end = min(totalPages, start + maxVisibleDots)
        return start..<end
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Левый индикатор
            if visibleRange.lowerBound > 0 {
                Image(systemName: "chevron.left")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Видимые точки
            ForEach(visibleRange, id: \.self) { index in
                Button(action: { onIndexChanged(index) }) {
                    Circle()
                        .fill(currentIndex == index ? Color.blue : Color.gray)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Правый индикатор
            if visibleRange.upperBound < totalPages {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct ChartsContent: View {
    let data: [HealthDataManager.DailyHealthData]
    
    var body: some View {
        VStack(spacing: 20) {
            // Steps Chart
            ChartCard(
                title: "Steps".localized,
                data: data.map { ChartData(date: $0.date, value: $0.steps) },
                color: .green,
                icon: "figure.walk"
            )
            
            // Active Energy Chart
            ChartCard(
                title: "Active Energy".localized,
                data: data.map { ChartData(date: $0.date, value: $0.activeEnergy) },
                color: .orange,
                icon: "flame.fill"
            )
            
            // Carbs Chart
            ChartCard(
                title: "Carbs".localized,
                data: data.map { ChartData(date: $0.date, value: $0.carbs) },
                color: .green,
                icon: "leaf.fill"
            )
            
            // Proteins Chart
            ChartCard(
                title: "Proteins".localized,
                data: data.map { ChartData(date: $0.date, value: $0.proteins) },
                color: .blue,
                icon: "drop.fill"
            )
            
            // Fats Chart
            ChartCard(
                title: "Fats".localized,
                data: data.map { ChartData(date: $0.date, value: $0.fats) },
                color: .yellow,
                icon: "circle.fill"
            )
            
            // Calories Chart
            ChartCard(
                title: "Calories".localized,
                data: data.map { ChartData(date: $0.date, value: $0.calories) },
                color: .red,
                icon: "bolt.fill"
            )
        }
        .padding()
    }
}

struct DailyDataTabView: View {
    let data: [HealthDataManager.DailyHealthData]
    let onExport: () -> Void
    @State private var selectedDayIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Export Button
            HStack {
                Text("Daily Data".localized)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button("Export CSV".localized) {
                    onExport()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Горизонтальный TabView по дням
            if !data.isEmpty {
                TabView(selection: $selectedDayIndex) {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, dailyData in
                        ScrollView {
                            VStack(spacing: 16) {
                                Text(dailyData.date, style: .date)
                                    .font(.title2)
                                    .bold()
                                    .padding(.top)
                                DailyDataCard(data: dailyData)
                                Spacer(minLength: 100)
                            }
                            .padding(.horizontal)
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            } else {
                Text("No daily data available".localized)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ChartsTabView: View {
    let data: [HealthDataManager.DailyHealthData]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Steps Chart
                ChartCard(
                    title: "Steps".localized,
                    data: data.map { ChartData(date: $0.date, value: $0.steps) },
                    color: .green,
                    icon: "figure.walk"
                )
                
                // Active Energy Chart
                ChartCard(
                    title: "Active Energy".localized,
                    data: data.map { ChartData(date: $0.date, value: $0.activeEnergy) },
                    color: .orange,
                    icon: "flame.fill"
                )
                
                // Carbs Chart
                ChartCard(
                    title: "Carbs".localized,
                    data: data.map { ChartData(date: $0.date, value: $0.carbs) },
                    color: .green,
                    icon: "leaf.fill"
                )
                
                // Proteins Chart
                ChartCard(
                    title: "Proteins".localized,
                    data: data.map { ChartData(date: $0.date, value: $0.proteins) },
                    color: .blue,
                    icon: "drop.fill"
                )
                
                // Fats Chart
                ChartCard(
                    title: "Fats".localized,
                    data: data.map { ChartData(date: $0.date, value: $0.fats) },
                    color: .yellow,
                    icon: "circle.fill"
                )
                
                // Calories Chart
                ChartCard(
                    title: "Calories".localized,
                    data: data.map { ChartData(date: $0.date, value: $0.calories) },
                    color: .red,
                    icon: "bolt.fill"
                )
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct ChartCard: View {
    let title: String
    let data: [ChartData]
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if data.count > 1 {
                Chart(data) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(color.opacity(0.1))
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
            } else {
                Text("Not enough data for chart".localized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
}

struct DailyDataCard: View {
    let data: HealthDataManager.DailyHealthData
    
    var body: some View {
        VStack(spacing: 16) {
            // Date Header
            HStack {
                Text(data.date, style: .date)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.blue)
            }
            
            // Data Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DataItem(title: "Steps".localized, value: "\(Int(data.steps))", icon: "figure.walk", color: .green)
                DataItem(title: "Active Energy".localized, value: "\(Int(data.activeEnergy)) kcal", icon: "flame.fill", color: .orange)
                DataItem(title: "Carbs".localized, value: String(format: "%.1f g", data.carbs), icon: "leaf.fill", color: .green)
                DataItem(title: "Proteins".localized, value: String(format: "%.1f g", data.proteins), icon: "drop.fill", color: .blue)
                DataItem(title: "Fats".localized, value: String(format: "%.1f g", data.fats), icon: "circle.fill", color: .yellow)
                DataItem(title: "Calories".localized, value: "\(Int(data.calories)) kcal", icon: "bolt.fill", color: .red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
}

struct DataItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HealthDataView()
} 
