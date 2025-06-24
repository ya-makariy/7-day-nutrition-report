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
        ZStack {
            // Полноэкранный фон
            Color(.systemBackground)
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Заголовок с минимальным отступом от статус-бара
                Text("Health Stats".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .background(Color(.systemBackground))
                    
                // Основной контент занимает всё доступное пространство
                ScrollView {
                    VStack(spacing: 24) {
                        // Выбор дат
                        VStack(alignment: .leading, spacing: 18) {
                            Text("Date Range".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 16) {
                                // Start Date
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Start Date".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Button(action: { showStartDatePicker = true }) {
                                        Text(dateString(startDate))
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(16)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(12)
                                    }
                                }
                                
                                // End Date
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("End Date".localized)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Button(action: { showEndDatePicker = true }) {
                                        Text(dateString(endDate))
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity)
                                            .padding(16)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                            
                        // Кнопка Fetch Data
                        Button(action: {
                            Task { await viewModel.fetchData(startDate: startDate, endDate: endDate) }
                        }) {
                            HStack(spacing: 12) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .scaleEffect(1.0)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.title2)
                                }
                                Text(viewModel.isLoading ? "Loading...".localized : "Fetch Data".localized)
                                    .font(.title3)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(viewModel.isLoading ? Color.gray : Color.blue)
                            .cornerRadius(16)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 20)
                            
                        // Ошибки
                        if let error = viewModel.error, !viewModel.noDataErrorShouldHide {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.title3)
                                Text(error)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(20)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                        }
                            
                        // Контент на основе выбранной вкладки
                        if !viewModel.dailyData.isEmpty {
                            if selectedTab == 0 {
                                DailyDataContent(data: viewModel.dailyData, onExport: {
                                    viewModel.exportCSV()
                                })
                            } else {
                                ChartsContent(data: viewModel.dailyData)
                            }
                        } else if !viewModel.isLoading && viewModel.error == nil {
                            // Пустое состояние
                            VStack(spacing: 20) {
                                Image(systemName: "heart.text.square")
                                    .font(.system(size: 80))
                                    .foregroundColor(.gray)
                                Text("No Data Available".localized)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                Text("Select a date range and tap 'Fetch Data' to get started.".localized)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 60)
                        }
                        
                        // Отступ для нижних вкладок
                        if !viewModel.dailyData.isEmpty {
                            Spacer().frame(height: 100)
                        }
                    }
                }
                    
                // Нижние вкладки
                if !viewModel.dailyData.isEmpty {
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color(.separator))
                        HStack(spacing: 0) {
                            // Daily Data Tab
                            Button(action: { selectedTab = 0 }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "calendar")
                                        .font(.title2)
                                    Text("Daily Data".localized)
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(selectedTab == 0 ? .blue : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Charts Tab
                            Button(action: { selectedTab = 1 }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                        .font(.title2)
                                    Text("Charts".localized)
                                        .font(.footnote)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(selectedTab == 1 ? .blue : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(Color(.systemBackground))
                    }
                }
            }
        }
        .onAppear {
            Task { await viewModel.requestAuthorization() }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = viewModel.csvURL {
                ShareSheet(activityItems: [url])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
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
        VStack(spacing: 20) {
            // Header with Export Button
            HStack {
                Text("Daily Data".localized)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
                .background(Color.blue)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 20)
            
            // Smart page control (максимум 7 точек)
            if data.count > 1 {
                SmartPageControl(
                    currentIndex: selectedDayIndex,
                    totalPages: data.count,
                    maxVisibleDots: 7,
                    onIndexChanged: { newIndex in
                        selectedDayIndex = newIndex
                    }
                )
                .padding(.horizontal, 20)
            }
            
            // Горизонтальный скролл по дням
            TabView(selection: $selectedDayIndex) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, dailyData in
                    DailyDataCard(data: dailyData)
                        .padding(.horizontal, 20)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 480)
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
        VStack(spacing: 24) {
            // Steps Chart
            ChartCard(
                title: "Steps".localized,
                data: data.map { ChartData(date: $0.date, value: $0.steps) },
                color: .green,
                emoji: "🚶"
            )
            
            // Active Energy Chart
            ChartCard(
                title: "Active Energy".localized,
                data: data.map { ChartData(date: $0.date, value: $0.activeEnergy) },
                color: .orange,
                emoji: "🔥"
            )
            
            // Carbs Chart
            ChartCard(
                title: "Carbs".localized,
                data: data.map { ChartData(date: $0.date, value: $0.carbs) },
                color: .green,
                emoji: "🍩"
            )
            
            // Proteins Chart
            ChartCard(
                title: "Proteins".localized,
                data: data.map { ChartData(date: $0.date, value: $0.proteins) },
                color: .blue,
                emoji: "🍗"
            )
            
            // Fats Chart
            ChartCard(
                title: "Fats".localized,
                data: data.map { ChartData(date: $0.date, value: $0.fats) },
                color: .yellow,
                emoji: "🧈"
            )
            
            // Calories Chart
            ChartCard(
                title: "Calories".localized,
                data: data.map { ChartData(date: $0.date, value: $0.calories) },
                color: .red,
                emoji: "🍽️"
            )
        }
        .padding(.horizontal, 20)
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
    let emoji: String
    
    private var xAxisValues: [Date] {
        // Уменьшаем количество подписей на оси дат для лучшей читаемости
        let sortedData = data.sorted { $0.date < $1.date }
        let count = sortedData.count
        
        if count <= 7 {
            return sortedData.map { $0.date }
        } else if count <= 14 {
            return stride(from: 0, to: count, by: 2).map { sortedData[$0].date }
        } else {
            return stride(from: 0, to: count, by: count/5).map { sortedData[$0].date }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(emoji)
                    .font(.title)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
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
                    .lineStyle(StrokeStyle(lineWidth: 4))
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(color.opacity(0.1))
                }
                .frame(height: 240)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
            } else {
                Text("Not enough data for chart".localized)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(height: 240)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity)
    }
}

struct DailyDataCard: View {
    let data: HealthDataManager.DailyHealthData
    
    var body: some View {
        VStack(spacing: 20) {
            // Date Header
            HStack {
                Text(data.date, style: .date)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "calendar.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            // Data Grid with emojis
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                DataItem(title: "Steps".localized, value: "\(Int(data.steps))", emoji: "🚶", color: .green)
                DataItem(title: "Active Energy".localized, value: "\(Int(data.activeEnergy)) kcal", emoji: "🔥", color: .orange)
                DataItem(title: "Carbs".localized, value: String(format: "%.1f g", data.carbs), emoji: "🍩", color: .green)
                DataItem(title: "Proteins".localized, value: String(format: "%.1f g", data.proteins), emoji: "🍗", color: .blue)
                DataItem(title: "Fats".localized, value: String(format: "%.1f g", data.fats), emoji: "🧈", color: .yellow)
                DataItem(title: "Calories".localized, value: "\(Int(data.calories)) kcal", emoji: "🍽️", color: .red)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity)
    }
}

struct DataItem: View {
    let title: String
    let value: String
    let emoji: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(emoji)
                    .font(.title)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .frame(maxWidth: .infinity)
        .frame(height: 110)
    }
}

#Preview {
    HealthDataView()
}
