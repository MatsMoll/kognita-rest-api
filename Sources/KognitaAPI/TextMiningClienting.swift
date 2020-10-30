import NIO
import Vapor
import SwiftMarkdown
import SwiftSoup

public protocol TextMiningClienting {
    /// Estimates how similar two text are to each other
    /// - Parameters:
    ///   - first: The first text to compare
    ///   - second: The second text to compare
    ///   - worker: The worker handeling the request
    func similarity(between first: String, and second: String) throws -> EventLoopFuture<ClientResponse>
}

struct TextMiningClientingFactory {
    var make: ((Request) -> TextMiningClienting)?

    mutating func use(_ make: @escaping ((Request) -> TextMiningClienting)) {
        self.make = make
    }
}

extension Application {
    private struct TextMiningClientingKey: StorageKey {
        typealias Value = TextMiningClientingFactory
    }

    var textMiningClienting: TextMiningClientingFactory {
        get { self.storage[TextMiningClientingKey.self] ?? .init() }
        set { self.storage[TextMiningClientingKey.self] = newValue }
    }
}

extension Request {
    var textMiningClienting: TextMiningClienting {
        application.textMiningClienting.make!(self)
    }
}

extension String {

    func indicesOf(string: String) -> [Int] {
        var indices = [Int]()
        var searchStartIndex = self.startIndex

        while searchStartIndex < self.endIndex,
            let range = self.range(of: string, range: searchStartIndex..<self.endIndex),
            !range.isEmpty {
            let index = distance(from: self.startIndex, to: range.lowerBound)
            indices.append(index)
            searchStartIndex = range.upperBound
        }

        return indices
    }

    func cleanMarkdown() throws -> String {
        let cleanText = try SwiftSoup.parse(markdownToHTML(self)).text()
        let latexIndentifier = "$$"
        let latexIndices = cleanText.indicesOf(string: latexIndentifier)
        var index = 0
        var resultString = ""
        var lastIndex = cleanText.startIndex
        let startIndex = cleanText.startIndex
        while index + 1 < latexIndices.count {
            let latexStartIndex = cleanText.index(startIndex, offsetBy: latexIndices[index])
            if latexStartIndex != lastIndex {
                resultString += cleanText[lastIndex..<latexStartIndex]
                lastIndex = latexStartIndex
            }
            let latexEndIndex = cleanText.index(startIndex, offsetBy: latexIndices[index + 1] + latexIndentifier.count)
            let substring = cleanText[latexStartIndex...latexEndIndex]
            if substring.contains("\n") {
                index += 1
            } else {
                lastIndex = latexEndIndex
                index += latexIndentifier.count
            }
        }
        if cleanText.endIndex != lastIndex {
            resultString += cleanText[lastIndex..<cleanText.endIndex]
        }
        return resultString
    }

    func clean(stopwords: Set<String>) -> String {
        var newString = ""
        let terms = self.split(separator: " ")
        for term in terms {
            if stopwords.contains(String(term.lowercased())) == false {
                newString += "\(term) "
            }
        }
        return newString
    }
}

struct PythonTextClient: TextMiningClienting {

    let client: Client
    let scheme: String
    let baseUrl: String
    let port: Int
    let logger: Logger

    private static let englishStopwords = Set(["i", "me", "my", "myself", "we", "our", "ours", "ourselves", "you", "your", "yours", "yourself", "yourselves", "he", "him", "his", "himself", "she", "her", "hers", "herself", "it", "its", "itself", "they", "them", "their", "theirs", "themselves", "what", "which", "who", "whom", "this", "that", "these", "those", "am", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "having", "do", "does", "did", "doing", "a", "an", "the", "and", "but", "if", "or", "because", "as", "until", "while", "of", "at", "by", "for", "with", "about", "against", "between", "into", "through", "during", "before", "after", "above", "below", "to", "from", "up", "down", "in", "out", "on", "off", "over", "under", "again", "further", "then", "once", "here", "there", "when", "where", "why", "how", "all", "any", "both", "each", "few", "more", "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very", "s", "t", "can", "will", "just", "don", "should", "now"])
    private static let norwegianStopwords = Set(["å", "alle", "andre", "at", "av", "både", "båe", "bare", "begge", "ble", "blei", "bli", "blir", "blitt", "bort", "bra", "bruke", "da", "då", "de", "deg", "dei", "deim", "deira", "deires", "dem", "den", "denne", "der", "dere", "deres", "det", "dette", "di", "din", "disse", "dit", "ditt", "du", "dykk", "dykkar", "eg", "ein", "eit", "eitt", "eller", "elles", "en", "ene", "eneste", "enhver", "enn", "er", "et", "ett", "etter", "få", "for", "før", "fordi", "forsøke", "først", "fra", "fram", "gå", "gjorde", "gjøre", "god", "ha", "hadde", "han", "hans", "har", "hennar", "henne", "hennes", "her", "hit", "hjå", "ho", "hoe", "honom", "hoss", "hossen", "hun", "hva", "hvem", "hver", "hvilke", "hvilken", "hvis", "hvor", "hvordan", "hvorfor", "i", "ikke", "ikkje", "ingen", "ingi", "inkje", "inn", "innen", "inni", "ja", "jeg", "kan", "kom", "korleis", "korso", "kun", "kunne", "kva", "kvar", "kvarhelst", "kven", "kvi", "kvifor", "lage", "lang", "lik", "like", "må", "man", "mange", "måte", "me", "med", "medan", "meg", "meget", "mellom", "men", "mens", "mer", "mest", "mi", "min", "mine", "mitt", "mot", "mye", "mykje", "nå", "når", "ned", "nei", "no", "noe", "noen", "noka", "noko", "nokon", "nokor", "nokre", "ny", "og", "også", "om", "opp", "oss", "over", "på", "rett", "riktig", "så", "samme", "sånn", "seg", "selv", "si", "sia", "sidan", "siden", "sin", "sine", "sist", "sitt", "sjøl", "skal", "skulle", "slik", "slutt", "so", "som", "somme", "somt", "start", "stille", "tid", "til", "tilbake", "um", "under", "upp", "ut", "uten", "være", "vært", "var", "vår", "vart", "varte", "ved", "verdi", "vere", "verte", "vi", "vil", "ville", "vite", "vore", "vors", "vort"])

    struct SimilarityData: Content {
        let org: String
        let text: String
    }

    func similarity(between first: String, and second: String) throws -> EventLoopFuture<ClientResponse> {

        var url = URI(path: "compare")
        url.scheme = scheme
        url.host = baseUrl
        url.port = port
        logger.log(level: .info, "Sending request \(url)", file: #file, function: #function, line: #line)
        return client.post(
            url,
            headers: .init([
                ("Accept", "application/json, text/plain, */*"),
                ("Content-Type", "application/json")
            ]),
            beforeSend: { (req) in
                try req.content.encode(
                    SimilarityData(
                        org: first.clean(stopwords: PythonTextClient.englishStopwords.union(PythonTextClient.norwegianStopwords)).cleanMarkdown(),
                        text: second.clean(stopwords: PythonTextClient.englishStopwords.union(PythonTextClient.norwegianStopwords)).cleanMarkdown()
                    )
                )
            })
            .flatMapErrorThrowing { error in
                self.logger.log(level: .critical, "Error: \(error), when estimating similarity")
                throw error
        }
    }
}
