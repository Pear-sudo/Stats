//
//  HistoricalChart.swift
//  Stats
//
//  Created by A on 02/09/2024.
//

import SwiftUI
import SwiftData
import Charts

struct HistoricalChart: View {
    
    var category: Category
    var instances: [Instance]
    
    init(category: Category, instances: [Instance]) {
        self.category = category
        self.instances = instances
        self.dailyDatas = HistoricalChart.getDailyData(instances: instances)
    }
    
    private let calendar = Calendar.current
    private let lineWidth: CGFloat = 2
    private var dailyDatas: [DailyData]
    
    @State private var selectedDataPoint: DailyData? = nil
    
    var body: some View {
        Chart(dailyDatas) { data in
            lineMark(data)
        }
        .chartXAxis(content: xAxis)
        .chartOverlay(content: overlay)
        .chartBackground(content: background)
        .padding()
    }
    
    // MARK: - Axis
    
    @AxisContentBuilder private func xAxis() -> some AxisContent {
        AxisMarks(values: dailyDatas.map(\.date)) { value in
            if let date = value.as(Date.self) {
                if calendar.isDateAtStartOfMonth(date) {
                    AxisValueLabel(format: .dateTime.month().day())
                } else {
                    AxisValueLabel(format: .dateTime.day())
                }
            }
            AxisGridLine()
            AxisTick()
        }
    }
    
    // MARK: - Subviews
    
    @ChartContentBuilder
    private func lineMark(_ data: DailyData) -> some ChartContent {
        let mark = LineMark(
            x: .value("Date", data.date),
            y: .value("Count", data.count)
        )
        if selectedDataPoint == data {
            mark.symbol {
                Circle().strokeBorder(.blue, lineWidth: 2).background(Circle().foregroundColor(.red)).frame(width: 11)
            }
        } else {
            mark.symbol(Circle().strokeBorder(lineWidth: lineWidth))
        }
    }
    
    @ViewBuilder private func overlay(proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            Rectangle().fill(.clear).contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture()
                        .onEnded { event in
                            handleGestureEvent(location: event.location, chartProxy: proxy, geometry: geometry, isTap: true)
                        }
                        .exclusively(
                            before: DragGesture().onChanged { event in
                                handleGestureEvent(location: event.location, chartProxy: proxy, geometry: geometry, isTap: false)
                            }
                        )
                )
        }
    }
    
    @ViewBuilder private func background(proxy: ChartProxy) -> some View {
        GeometryReader { geo in
            if let selectedDataPoint {
                let deltaX = proxy.position(forX: selectedDataPoint.date) ?? 0
                
                let plotFrame = geo[proxy.plotFrame!]
                
                let lineX = deltaX + plotFrame.origin.x
                let lineHeight = plotFrame.height
                let lineWidth: CGFloat = 2
                
                let boxWidth: CGFloat = 100
                let boxOffset: CGFloat = {
                    let offset = max(0, min(plotFrame.width - boxWidth, lineX - boxWidth / 2))
                    if lineX == plotFrame.maxX {
                        return offset + lineWidth
                    }
                    if lineX == plotFrame.minX {
                        return offset - lineWidth
                    }
                    return offset
                }()
                
                Rectangle()
                    .fill(.red)
                    .frame(width: lineWidth, height: lineHeight)
                    .position(x: lineX, y: lineHeight / 2)
                
                VStack(alignment: .center) {
                    Text("\(selectedDataPoint.date, format: .dateTime.year().month().day())")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("\(selectedDataPoint.count, format: .number)")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .padding(.top, 1)
                .frame(width: boxWidth, alignment: .center)
                .background {
                    UnevenRoundedRectangle(cornerRadii: .init(
                        bottomLeading: lineX == plotFrame.minX ? 0 : 8,
                        bottomTrailing: lineX == plotFrame.maxX ? 0 : 8
                    ))
                    .fill(.background)
                }
                .offset(x: boxOffset)
            }
        }
    }
    
    // MARK: - Interactivity
    
    private func handleGestureEvent(
        location: CGPoint,
        chartProxy: ChartProxy,
        geometry: GeometryProxy,
        isTap: Bool
    ) {
        let relativeXPosition = location.x - geometry[chartProxy.plotFrame!].origin.x
        let data = dailyDatas
        var index: Int? = nil
        if let date = chartProxy.value(atX: relativeXPosition) as Date? {
            // Find the closest date element.
            var minDistance: TimeInterval = .infinity
            for salesDataIndex in data.indices {
                let nthSalesDataDistance = data[salesDataIndex].date.distance(to: date)
                if abs(nthSalesDataDistance) < minDistance {
                    minDistance = abs(nthSalesDataDistance)
                    index = salesDataIndex
                }
            }
        }
        guard let index else {
            selectedDataPoint = nil
            return
        }
        // index is not nil now
        let newSelectedDataPoint = dailyDatas[index]
        if isTap, let selectedDataPoint, newSelectedDataPoint == selectedDataPoint {
            self.selectedDataPoint = nil
            return
        }
        selectedDataPoint = newSelectedDataPoint
    }
    
    // MARK: - Data
    
    private static func getDailyData(instances: [Instance]) -> [DailyData] {
        let calendar =  Calendar.current
        var dataMap = [Date:DailyData]()
        instances.forEach { instance in
            let key = calendar.startOfDay(for: instance.start)
            var data = dataMap[key, default: DailyData(date: key, count: 0)]
            data.count += instance.count
            dataMap[key] = data
        }
        return Array(dataMap.values).sorted(by: {$0.date > $1.date})
    }
    
    private struct DailyData: Identifiable, Comparable {
        
        static func < (lhs: HistoricalChart.DailyData, rhs: HistoricalChart.DailyData) -> Bool {
            lhs.date == rhs.date && lhs.count == rhs.count
        }
        
        var date: Date
        var count: Int
        var id: Date {
            date
        }
    }
}

// MARK: - extensions

fileprivate extension Calendar {
    func isDateAtEndOfMonth(_ date: Date) -> Bool {
        guard let range = self.range(of: .day, in: .month, for: date) else {
            return false
        }
        let lastDay = range.upperBound - 1
        let dayComponent = self.component(.day, from: date)
        return dayComponent == lastDay
    }
}

fileprivate extension Calendar {
    func isDateAtStartOfMonth(_ date: Date) -> Bool {
        guard let range = self.range(of: .day, in: .month, for: date) else {
            return false
        }
        let firstDay = range.lowerBound
        let dayComponent = self.component(.day, from: date)
        return dayComponent == firstDay
    }
}

// MARK: - Preview

fileprivate struct HistoricalChartWrapper: View {
    @Environment(\.modelContext) private var context
    @Query var categories: [Category]
    var body: some View {
        HistoricalChart(category: categories.first!, instances: instances)
    }
    
    var instances: [Instance] {
        let category = categories.first!.name
        return try! context.fetch(
            FetchDescriptor(predicate:
                                #Predicate<Instance>{$0.category.name == category}
                           )
        )
    }
}

#Preview {
    HistoricalChartWrapper()
        .modelContainer(for: models, inMemory: false)
        .frame(width: 300)
}
