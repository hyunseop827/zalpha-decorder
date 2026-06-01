//
//  SavedSlangRules.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

enum SavedSlangLimits {
    static let maximumVariantCount = 8
    static let maximumExampleCount = 3
}

enum SavedSlangExampleAppendResult {
    case saved
    case duplicate
    case full
    case invalid
}

enum SavedSlangRules {

    static func normalize(_ value: String) -> String {
        let quoteCharacters = CharacterSet(charactersIn: "\"'“”‘’")
        let edgeCharacters = CharacterSet.whitespacesAndNewlines
            .union(.punctuationCharacters)
            .union(quoteCharacters)

        let withoutQuotes = value
            .components(separatedBy: quoteCharacters)
            .joined()
        let collapsedWhitespace = withoutQuotes
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return collapsedWhitespace
            .trimmingCharacters(in: edgeCharacters)
            .lowercased()
    }

    static func inferredLanguageName(for text: String) -> String {
        if text.unicodeScalars.contains(where: { scalar in
            switch scalar.value {
            case 0x1100...0x11FF, 0x3130...0x318F, 0xAC00...0xD7AF, 0xA960...0xA97F, 0xD7B0...0xD7FF:
                return true
            default:
                return false
            }
        }) {
            return "한국어"
        }

        if text.unicodeScalars.contains(where: { scalar in
            switch scalar.value {
            case 0x3040...0x30FF:
                return true
            default:
                return false
            }
        }) {
            return "Japanese"
        }

        if text.unicodeScalars.contains(where: { scalar in
            switch scalar.value {
            case 0x0400...0x04FF:
                return true
            default:
                return false
            }
        }) {
            return "Russian"
        }

        return "English"
    }

    static func resolvedExpressionLanguage(_ expressionLanguage: String) -> String {
        let trimmedLanguage = expressionLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedLanguage.isEmpty ? "Unknown" : trimmedLanguage
    }

    static func resolvedMeaningLanguage(_ meaningLanguage: String, noteMeaningLanguage: String) -> String {
        let noteMeaningLanguage = noteMeaningLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMeaningLanguage = meaningLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedMeaningLanguage.isEmpty
            ? (noteMeaningLanguage.isEmpty ? "English" : noteMeaningLanguage)
            : trimmedMeaningLanguage
    }

    static func appendUnique(_ value: String, to values: inout [String]) -> Bool {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedValue = normalize(trimmedValue)

        guard !trimmedValue.isEmpty, !normalizedValue.isEmpty else {
            return false
        }

        let existingValues = Set(values.map(normalize))
        guard !existingValues.contains(normalizedValue),
              values.count < SavedSlangLimits.maximumVariantCount else {
            return false
        }

        values.append(trimmedValue)
        return true
    }

    static func appendUniqueExample(_ example: SavedSlangExample, to examples: inout [SavedSlangExample]) -> SavedSlangExampleAppendResult {
        let trimmedSentence = example.sentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMeaning = example.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedSentence = normalize(trimmedSentence)

        guard !trimmedSentence.isEmpty,
              !trimmedMeaning.isEmpty,
              !normalizedSentence.isEmpty else {
            return .invalid
        }

        guard examples.count < SavedSlangLimits.maximumExampleCount else {
            return .full
        }

        let existingSentences = Set(examples.map { normalize($0.sentence) })
        guard !existingSentences.contains(normalizedSentence) else {
            return .duplicate
        }

        examples.append(
            SavedSlangExample(
                id: example.id,
                sentence: trimmedSentence,
                meaning: trimmedMeaning,
                createdAt: example.createdAt
            )
        )
        return .saved
    }
}
