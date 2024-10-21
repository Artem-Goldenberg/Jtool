//
// Created for UICalendarView_SwiftUI
// by Stewart Lynch on 2022-07-01
// Using Swift 5.0
//
// Follow me on Twitter: @StewartLynch
// Subscribe on YouTube: https://youTube.com/StewartLynch
//

import SwiftUI

struct CalendarView: UIViewRepresentable {
    @Binding var date: Date?
    @EnvironmentObject var store: EventStore

    func makeUIView(context: Context) -> some UICalendarView {
        let view = UICalendarView()
        view.delegate = context.coordinator
        view.calendar = Calendar(identifier: .gregorian)
        view.availableDateRange = .init(start: .distantPast, end: .distantFuture)
        let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        view.selectionBehavior = dateSelection
        view.wantsDateDecorations = true
        return view
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func updateUIView(_ uiView: some UICalendarView, context: Context) {
        let components = store.events.map { event in
            let dateComponents = Calendar.current.dateComponents(
                [.day, .month, .year],
                from: event.timing.start
            )
            return dateComponents
        }
        uiView.reloadDecorations(
            forDateComponents: Array(Set(components)),
            animated: true
        )
    }

    class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
        let parent: CalendarView

        init(parent: CalendarView) {
            self.parent = parent
        }

        @MainActor
        func calendarView(
            _ calendarView: UICalendarView,
            decorationFor dateComponents: DateComponents
        ) -> UICalendarView.Decoration? {
            let foundEvents = dateComponents.date.map(parent.store.events(on:)) ?? []

            if foundEvents.isEmpty { return nil }
            if foundEvents.count == 1 {
                return .default(color: .systemOrange, size: .small)
            }
            // count >= 2
            return .image(UIImage(systemName: "square.stack.fill"), color: .systemBlue, size: .medium)
        }

        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            didSelectDate dateComponents: DateComponents?
        ) {
            parent.date = dateComponents?.date
        }

        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            canSelectDate dateComponents: DateComponents?
        ) -> Bool { true }

    }

}
