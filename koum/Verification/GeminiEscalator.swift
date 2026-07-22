import Foundation

/// LLM escalation for ambiguous scans. Never asks "is this X?" — the model
/// would agree. Asks "what passage is this?" and compares the answer to the
/// target. Chapter-level match is deliberate: if the user has the right
/// chapter open, they have done the thing.
///
/// Text only, never images. 3-second hard timeout. Entirely optional — with
/// no API key configured this returns `.unavailable` and the caller falls
/// back to offline thresholds.
struct GeminiEscalator: Sendable {

    enum Outcome: Sendable {
        case pass
        case fail
        case unavailable
    }

    struct Identified: Decodable {
        let book: String?
        let chapter: Int?
        let verse: Int?
        let confidence: Double?
    }

    static var isConfigured: Bool { !KoumConfig.geminiAPIKey.isEmpty }

    func identify(ocrText: String, target: VerseRef) async -> Outcome {
        guard Self.isConfigured else { return .unavailable }

        let system = """
        You identify Bible passages from OCR text. The text may contain errors, \
        partial words, and interleaved columns. Respond with ONLY a JSON object, \
        no markdown, no explanation: \
        {"book":"...","chapter":N,"verse":N,"confidence":0.0-1.0} \
        If you cannot identify a passage, return \
        {"book":null,"chapter":null,"verse":null,"confidence":0.0}
        """

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": system]]],
            "contents": [["parts": [["text": String(ocrText.prefix(2000))]]]],
            "generationConfig": [
                "temperature": 0,
                "maxOutputTokens": 60,
                "responseMimeType": "application/json",
            ],
        ]

        guard let url = URL(string:
            "https://generativelanguage.googleapis.com/v1beta/models/\(KoumConfig.geminiModel):generateContent"
        ) else { return .unavailable }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(KoumConfig.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = KoumConfig.escalationTimeout
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return .unavailable
            }
            guard let text = Self.extractText(from: data),
                  let jsonData = text.data(using: .utf8),
                  let identified = try? JSONDecoder().decode(Identified.self, from: jsonData)
            else { return .unavailable }

            guard let book = identified.book, let chapter = identified.chapter else {
                return .fail
            }
            // Chapter-level match; book names normalized loosely.
            if Self.booksMatch(book, target.book), chapter == target.chapter {
                return .pass
            }
            return .fail
        } catch {
            return .unavailable
        }
    }

    private static func extractText(from data: Data) -> String? {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = obj["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String
        else { return nil }
        return text
    }

    static func booksMatch(_ a: String, _ b: String) -> Bool {
        func norm(_ s: String) -> String {
            var t = s.lowercased()
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: " ", with: "")
            // psalm/psalms, song of songs/solomon
            if t == "psalm" { t = "psalms" }
            if t.hasPrefix("songof") { t = "songofsolomon" }
            if t == "revelations" { t = "revelation" }
            return t
        }
        let na = norm(a), nb = norm(b)
        return na == nb || na.hasPrefix(nb) || nb.hasPrefix(na)
    }
}
