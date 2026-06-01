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
    let expression: String
    let normalizedExpression: String
    let expressionLanguage: String
    let meaningLanguage: String
    var meanings: [String]
    var originalExpressions: [String]
    var examples: [SavedSlangExample]
    let createdAt: Date
    var updatedAt: Date
    var seenCount: Int

    init(
        id: UUID,
        expression: String,
        normalizedExpression: String,
        expressionLanguage: String,
        meaningLanguage: String,
        meanings: [String],
        originalExpressions: [String],
        examples: [SavedSlangExample] = [],
        createdAt: Date,
        updatedAt: Date,
        seenCount: Int
    ) {
        self.id = id
        self.expression = expression
        self.normalizedExpression = normalizedExpression
        self.expressionLanguage = expressionLanguage
        self.meaningLanguage = meaningLanguage
        self.meanings = meanings
        self.originalExpressions = originalExpressions
        self.examples = examples
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.seenCount = seenCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let oldContainer = try decoder.container(keyedBy: LegacyCodingKeys.self)
        let decodedExpression = try container.decodeIfPresent(String.self, forKey: .expression)
        let decodedSourceExpression = try oldContainer.decodeIfPresent(String.self, forKey: .sourceExpression)
        let decodedTranslatedExpressions = try oldContainer.decodeIfPresent([String].self, forKey: .translatedExpressions) ?? []
        let migratedExpression = decodedTranslatedExpressions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
        let isMigratingTranslatedExpression = decodedExpression == nil && migratedExpression != nil
        let decodedNormalizedExpression = try container.decodeIfPresent(String.self, forKey: .normalizedExpression)
        let fallbackExpression = decodedExpression ?? migratedExpression ?? decodedSourceExpression ?? decodedNormalizedExpression ?? ""
        let decodedCreatedAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        let decodedUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        let decodedOriginalExpressions = try container.decodeIfPresent([String].self, forKey: .originalExpressions)
        let migratedOriginalExpressions = decodedSourceExpression
            .map { [$0] } ?? []

        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        expression = fallbackExpression
        normalizedExpression = (isMigratingTranslatedExpression ? nil : decodedNormalizedExpression)
            ?? SavedSlangRules.normalize(fallbackExpression)
        expressionLanguage = try container.decodeIfPresent(String.self, forKey: .expressionLanguage)
            ?? SavedSlangRules.inferredLanguageName(for: expression)
        meaningLanguage = try container.decodeIfPresent(String.self, forKey: .meaningLanguage) ?? "English"
        meanings = try container.decodeIfPresent([String].self, forKey: .meanings) ?? []
        originalExpressions = (decodedOriginalExpressions ?? migratedOriginalExpressions)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        examples = (try container.decodeIfPresent([SavedSlangExample].self, forKey: .examples) ?? [])
            .filter { !$0.sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .prefix(SavedSlangLimits.maximumExampleCount)
            .map { $0 }
        createdAt = decodedCreatedAt ?? decodedUpdatedAt ?? Date(timeIntervalSince1970: 0)
        updatedAt = decodedUpdatedAt ?? createdAt
        seenCount = try container.decodeIfPresent(Int.self, forKey: .seenCount) ?? 1
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case expression
        case normalizedExpression
        case expressionLanguage
        case meaningLanguage
        case meanings
        case originalExpressions
        case examples
        case createdAt
        case updatedAt
        case seenCount
    }

    private enum LegacyCodingKeys: String, CodingKey {
        case sourceExpression
        case translatedExpressions
    }
}
