extension Array where Element: Identifiable {
    func first(with id: Element.ID) -> Element? {
        first { $0.id == id }
    }

    func firstIndex(with id: Element.ID) -> Int? {
        firstIndex { $0.id == id }
    }
}

extension Array {
    var lastIndex: Int? {
        isEmpty ? nil : endIndex - 1
    }

    var firstIndex: Int? {
        isEmpty ? nil : startIndex
    }
}
