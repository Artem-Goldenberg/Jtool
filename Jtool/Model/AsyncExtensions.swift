extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        let initialCapacity = underestimatedCount
        if initialCapacity == 0 { return [] }

        var result = ContiguousArray<T>()
        result.reserveCapacity(initialCapacity)

        var iterator = self.makeIterator()

        // Add elements up to the initial capacity without checking for regrowth.
        for _ in 0..<initialCapacity {
            result.append(try await transform(iterator.next()!))
        }
        // Add remaining elements, if any.
        while let element = iterator.next() {
            result.append(try await transform(element))
        }
        return Array(result)
    }

    func asyncCompactMap<T>(_ transform: (Element) async throws -> T?) async rethrows -> [T] {
        let initialCapacity = underestimatedCount
        if initialCapacity == 0 { return [] }

        var result = ContiguousArray<T>()
        result.reserveCapacity(initialCapacity)

        var iterator = self.makeIterator()

        // Add elements up to the initial capacity without checking for regrowth.
        for _ in 0..<initialCapacity {
            if let value = try await transform(iterator.next()!) {
                result.append(value)
            }
        }
        // Add remaining elements, if any.
        while let element = iterator.next() {
            if let value = try await transform(element) {
                result.append(value)
            }
        }
        return Array(result)
    }

    func concurrentMap<T>(_ transform: @escaping (Element) async throws -> T) async rethrows -> [T] {
        let tasks = map { element in
            Worker {
                try await transform(element)
            }
        }
        return try await tasks.asyncMap { task in
            try await task.value
        }
    }

    func concurrentCompactMap<T>(_ transform: @escaping (Element) async throws -> T?) async rethrows -> [T] {
        let tasks = map { element in
            Worker {
                try await transform(element)
            }
        }
        return try await tasks.asyncCompactMap { task in
            try await task.value
        }
    }
}
