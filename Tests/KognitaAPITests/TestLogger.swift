protocol TestLogger: class {

    associatedtype Entry

    var logs: [Entry] { get set }

    func clear()
    func log(entry: Entry)
}

extension TestLogger {
    func clear() { logs = [] }
    func log(entry: Entry) { logs.append(entry) }
}
