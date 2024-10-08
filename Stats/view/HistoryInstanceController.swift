//
//  HistoryInstanceController.swift
//  Stats
//
//  Created by A on 01/09/2024.
//

import SwiftUI
import SwiftData
import Combine

struct HistoryInstanceController: View {
    
    @Binding var date: Date
    
    @State private var datePickerIsShown = false
    
    private let calendar =  Calendar.current
    
    var body: some View {
        HStack {
            Text(date, style: .date)
                .font(.headline)
                .frame(minWidth: 130, alignment: .trailing)
                .onTapGesture {
                    onDateTextTap()
                }
                .popover(isPresented: $datePickerIsShown) {
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                        .labelsHidden()
                        .datePickerStyle(.graphical)
                        .padding()
                }
                .contextMenu {
                    if !calendar.isDateInToday(date) {
                        Button("Today") {
                            date = .now
                        }
                    }
                }
            Stepper(
                value: $date,
                step: -60 * 60 * 24
            ) {}
            
        }
        .onHover { bool in
            onHoverDateController(bool)
        }
    }
    
    private func onDateTextTap() {
        datePickerIsShown.toggle()
    }
    
    private func onHoverDateController(_ b: Bool) {
        if b {
            if trackScrollWheelCancellable == nil {
                trackScrollWheel()
            }
        } else {
            trackScrollWheelCancellable?.cancel()
            trackScrollWheelCancellable = nil
        }
    }
    
    @State var trackScrollWheelCancellable: Cancellable?
    private func trackScrollWheel() {
        trackScrollWheelCancellable =
        NSApp.publisher(for: \.currentEvent)
            .filter { event in event?.type == .scrollWheel }
            .throttle(for: .milliseconds(200),
                      scheduler: DispatchQueue.main,
                      latest: true)
            .compactMap { $0 }
            .filter { event in
                abs(event.scrollingDeltaY) > 3
            }
            .sink { event in
                if event.scrollingDeltaY < 0 {
                    date = calendar.date(byAdding: .day, value: 1, to: date)!
                } else {
                    date = calendar.date(byAdding: .day, value: -1, to: date)!
                }
            }
    }
}

fileprivate struct HistoryInstanceControllerWrapper: View {
    @State private var date = Date.now
    var body: some View {
        HistoryInstanceController(date: $date)
            .padding()
    }
}

#Preview {
    HistoryInstanceControllerWrapper()
        .modelContainer(for: models, inMemory: false)
}
