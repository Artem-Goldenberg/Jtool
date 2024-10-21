//
// Created for Custom Calendar
// by  Stewart Lynch on 2024-01-22
//
// Follow me on Mastodon: @StewartLynch@iosdev.space
// Follow me on Threads: @StewartLynch (https://www.threads.net)
// Follow me on X: https://x.com/StewartLynch
// Follow me on LinkedIn: https://linkedin.com/in/StewartLynch
// Subscribe on YouTube: https://youTube.com/@StewartLynch
// Buy me a ko-fi:  https://ko-fi.com/StewartLynch


import Foundation

extension Date: Identifiable {
    public var id: Date {
//        Int(self.timeIntervalSince1970)
        self
    }

    var monthInt: Int {
        Calendar.current.component(.month, from: self)
    }

    var dayNum: Int {
        Calendar.current.component(.day, from: self)
    }

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var isMonthStart: Bool {
        Calendar.current.date(
            self, matchesComponents: .init(day: 1)
        )
    }
    var monthName: String {
        Calendar.current.shortMonthSymbols[
            Calendar.current.component(.month, from: self) - 1
        ]
    }
}

extension DateInterval {
    var middle: Date {
        Date(
            timeIntervalSince1970:
                (start.timeIntervalSince1970 + end.timeIntervalSince1970) / 2
        )
    }

    var days: [Date] {
        var result = [Date]()

        Calendar.current.enumerateDates(
            startingAfter: start.startOfDay - 1,
            matching: DateComponents(hour: 0, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) { date, isStrict, stop in
            guard let date else { return }
            if date <= end {
                result.append(date)
            } else {
                stop = true
            }
        }

        return result
//
//        var result = [Date]()
//        var day = start.startOfDay
//        while day <= end {
//            result.append(day)
//            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!.startOfDay
//        }
//        return result
    }

    func days(withSelectionFrom range: DateInterval) -> (days: [Int], selected: [Int].Indices) {
        let selectionRange = intersection(with: range) ?? .init()
        var result = [Int]()
        var day = start
        var i = 0
        var selection = (0, 0)
        var selecting = false

        while day <= end {
            if !selecting, selectionRange.contains(day) {
                selection.0 = i
                selecting = true
            }

            result.append(day.dayNum)
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!

            if selecting, !selectionRange.contains(day) {
                selection.1 = i
                selecting = false
            }

            i += 1
        }

        if selecting {
            selection.1 = i - 1
            selecting = false
        }

        return (result, .init(uncheckedBounds: selection))
    }
}
