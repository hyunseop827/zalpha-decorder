//
//  AIServiceModels.swift
//  ZalphaDecoder
//

import Foundation

/// Normalized AI errors that the UI can map to user-facing messages.
enum AIServiceError: Error {
    case emptyResponse
    case blocked
    case rateLimited
    case networkUnavailable
    case serviceUnavailable
    case configuration
    case invalidResponse
}

/// Structured Decode Note that can later become a vocabulary item.
struct DecodeNote: Codable {
    let expression: String
    let meaning: String
    let meaningLanguage: String
    let originalExpression: String

    init(
        expression: String,
        meaning: String,
        meaningLanguage: String = "English",
        originalExpression: String
    ) {
        self.expression = expression
        self.meaning = meaning
        self.meaningLanguage = meaningLanguage
        self.originalExpression = originalExpression
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let legacyContainer = try decoder.container(keyedBy: LegacyCodingKey.self)
        expression = try container.decodeIfPresent(String.self, forKey: .expression)
            ?? legacyContainer.decodeIfPresent(String.self, forKey: .oldTargetExpression)
            ?? ""
        meaning = try container.decodeIfPresent(String.self, forKey: .meaning) ?? ""
        meaningLanguage = try container.decodeIfPresent(String.self, forKey: .meaningLanguage) ?? "English"
        originalExpression = try container.decodeIfPresent(String.self, forKey: .originalExpression)
            ?? legacyContainer.decodeIfPresent(String.self, forKey: .oldOriginalExpression)
            ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(expression, forKey: .expression)
        try container.encode(meaning, forKey: .meaning)
        try container.encode(meaningLanguage, forKey: .meaningLanguage)
        try container.encode(originalExpression, forKey: .originalExpression)
    }

    private enum CodingKeys: String, CodingKey {
        case expression
        case meaning
        case meaningLanguage
        case originalExpression
    }

    private struct LegacyCodingKey: CodingKey {
        let stringValue: String
        let intValue: Int? = nil

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }

        static let oldOriginalExpression = LegacyCodingKey(stringValue: "source" + "Expression")!
        static let oldTargetExpression = LegacyCodingKey(stringValue: "translated" + "Expression")!
    }
}

/// Parsed Gemini response containing the final decoded output and optional notes.
struct DecodeResult: Decodable {
    let result: String
    let notes: [DecodeNote]
}

/// Generated example sentence for a saved slang expression.
struct GeneratedSlangExample: Decodable {
    let sentence: String
    let meaning: String
}
