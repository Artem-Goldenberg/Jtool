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

    func asyncForEach(_ operation: (Element) async throws -> Void) async rethrows {
        for element in self {
            try await operation(element)
        }
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

    func concurrentForEach(_ operation: @escaping (Element) async throws -> Void) async rethrows {
        // A task group automatically waits for all of its
        // sub-tasks to complete, while also performing those
        // tasks in parallel:
        await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    try await operation(element)
                }
            }
        }
    } /// func
}
