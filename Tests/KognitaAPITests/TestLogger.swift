protocol TestLogger: class {

    associatedtype Entry

    var logs: [Entry] { get set }

    var lastEntry: Entry? { get }
    var isEmpty: Bool { get }

    func clear()
    func log(entry: Entry)
}

extension TestLogger {
    func clear() { logs = [] }
    func log(entry: Entry) { logs.append(entry) }

    var lastEntry: Entry? { logs.last }
    var isEmpty: Bool { logs.isEmpty }
}
