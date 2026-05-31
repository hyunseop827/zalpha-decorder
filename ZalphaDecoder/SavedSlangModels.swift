//
//  SavedSlangModels.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

/// Example sentence generated for a saved slang expression.
struct SavedSlangExample: Codable, Identifiable {
    let id: UUID
    let sentence: String
    let meaning: String
    let createdAt: Date

    init(
        id: UUID,
        sentence: String,
        meaning: String,
        createdAt: Date
    ) {
        self.id = id
        self.sentence = sentence
        self.meaning = meaning
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        sentence = try container.decodeIfPresent(String.self, forKey: .sentence) ?? ""
        meaning = try container.decodeIfPresent(String.self, forKey: .meaning) ?? ""
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
            ?? Date(timeIntervalSince1970: 0)
    }
}

/// Locally saved slang or expression collected from Decode Notes.
struct SavedSlang: Codable, Identifiable {
    let id: UUID
    let sourceExpression: String
    let normalizedExpression: String
    let sourceLanguage: String
    let meaningLanguage: String
    var meanings: [String]
    var translatedExpressions: [String]
    var examples: [SavedSlangExample]
    let createdAt: Date
    var updatedAt: Date
    var seenCount: Int

    init(
        id: UUID,
        sourceExpression: String,
        normalizedExpression: String,
        sourceLanguage: String,
        meaningLanguage: String,
        meanings: [String],
        translatedExpressions: [String],
        examples: [SavedSlangExample] = [],
        createdAt: Date,
        updatedAt: Date,
        seenCount: Int
    ) {
        self.id = id
        self.sourceExpression = sourceExpression
        self.normalizedExpression = normalizedExpression
        self.sourceLanguage = sourceLanguage
        self.meaningLanguage = meaningLanguage
        self.meanings = meanings
        self.translatedExpressions = translatedExpressions
        self.examples = examples
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.seenCount = seenCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let decodedSourceExpression = try container.decodeIfPresent(String.self, forKey: .sourceExpression)
        let decodedNormalizedExpression = try container.decodeIfPresent(String.self, forKey: .normalizedExpression)
        let fallbackExpression = decodedSourceExpression ?? decodedNormalizedExpression ?? ""
        let decodedCreatedAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        let decodedUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        sourceExpression = fallbackExpression
        normalizedExpression = decodedNormalizedExpression ?? SavedSlangRules.normalize(fallbackExpression)
        sourceLanguage = try container.decodeIfPresent(String.self, forKey: .sourceLanguage)
            ?? SavedSlangRules.inferredLanguageName(for: sourceExpression)
        meaningLanguage = try container.decodeIfPresent(String.self, forKey: .meaningLanguage) ?? "English"
        meanings = try container.decodeIfPresent([String].self, forKey: .meanings) ?? []
        translatedExpressions = try container.decodeIfPresent([String].self, forKey: .translatedExpressions) ?? []
        examples = (try container.decodeIfPresent([SavedSlangExample].self, forKey: .examples) ?? [])
            .filter { !$0.sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(SavedSlangLimits.maximumExampleCount)
            .map { $0 }
        createdAt = decodedCreatedAt ?? decodedUpdatedAt ?? Date(timeIntervalSince1970: 0)
        updatedAt = decodedUpdatedAt ?? createdAt
        seenCount = try container.decodeIfPresent(Int.self, forKey: .seenCount) ?? 1
    }
}
