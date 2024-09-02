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
    
    private let calendar = Calendar.current
    private let lineWidth: CGFloat = 2
    
    @State private var selectedDataPoint: DailyData? = nil
    
    var body: some View {
        Chart(dailyDatas) { data in
            lineMark(data)
        }
        .chartOverlay(content: overlay)
        .chartBackground(content: background)
        .padding()
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
            if
                let selectedDataPoint {
                let dateInterval = Calendar.current.dateInterval(of: .day, for: selectedDataPoint.date)!
                let startPositionX1 = proxy.position(forX: dateInterval.start) ?? 0
                
                let lineX = startPositionX1 + geo[proxy.plotFrame!].origin.x
                let lineHeight = geo[proxy.plotFrame!].maxY
                let boxWidth: CGFloat = 100
                let boxOffset = max(0, min(geo.size.width - boxWidth, lineX - boxWidth / 2))
                
                Rectangle()
                    .fill(.red)
                    .frame(width: 2, height: lineHeight)
                    .position(x: lineX, y: lineHeight / 2)
                
                VStack(alignment: .center) {
                    Text("\(selectedDataPoint.date, format: .dateTime.year().month().day())")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Text("\(selectedDataPoint.count, format: .number)")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                .frame(width: boxWidth, alignment: .leading)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.background)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.quaternary.opacity(0.7))
                    }
                    .padding(.horizontal, -8)
                    .padding(.vertical, -4)
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
    
    private var dailyDatas: [DailyData] {
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
