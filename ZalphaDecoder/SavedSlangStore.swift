//
//  SavedSlangStore.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

/// Small UserDefaults-backed store for saved slang notes.
final class SavedSlangStore {
    static let shared = SavedSlangStore()

    private let persistence: SavedSlangPersistence

    private init(userDefaults: UserDefaults = .standard) {
        persistence = SavedSlangPersistence(userDefaults: userDefaults)
    }

    /// Loads saved slang items sorted by most recently updated first.
    func loadItems() -> [SavedSlang] {
        persistence.loadItems()
    }

    /// Saves one Decode Note, deduplicating by normalized source expression and language pair.
    @discardableResult
    func save(_ note: DecodeNote, sourceLanguage: String, meaningLanguage: String) -> SavedSlangSaveResult {
        let sourceExpression = note.sourceExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedExpression = SavedSlangRules.normalize(sourceExpression)
        let sourceLanguage = SavedSlangRules.resolvedSourceLanguage(sourceLanguage)
        let meaningLanguage = SavedSlangRules.resolvedMeaningLanguage(
            meaningLanguage,
            noteMeaningLanguage: note.meaningLanguage
        )

        guard !sourceExpression.isEmpty, !normalizedExpression.isEmpty else {
            return .invalid
        }

        let meaning = note.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
        let translatedExpression = note.translatedExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        var items = loadItems()

        guard let existingIndex = items.firstIndex(where: {
            $0.normalizedExpression == normalizedExpression
                && $0.sourceLanguage.caseInsensitiveCompare(sourceLanguage) == .orderedSame
                && $0.meaningLanguage.caseInsensitiveCompare(meaningLanguage) == .orderedSame
        }) else {
            let item = SavedSlang(
                id: UUID(),
                sourceExpression: sourceExpression,
                normalizedExpression: normalizedExpression,
                sourceLanguage: sourceLanguage,
                meaningLanguage: meaningLanguage,
                meanings: meaning.isEmpty ? [] : [meaning],
                translatedExpressions: translatedExpression.isEmpty ? [] : [translatedExpression],
                examples: [],
                createdAt: now,
                updatedAt: now,
                seenCount: 1
            )
            items.insert(item, at: 0)
            persistence.save(items)
            return .saved
        }

        var item = items[existingIndex]
        let didAddMeaning = SavedSlangRules.appendUnique(meaning, to: &item.meanings)
        let didAddTranslatedExpression = SavedSlangRules.appendUnique(translatedExpression, to: &item.translatedExpressions)
        if didAddMeaning || didAddTranslatedExpression {
            item.updatedAt = now
        }
        item.seenCount += 1
        items[existingIndex] = item
        persistence.save(items)

        return didAddMeaning || didAddTranslatedExpression ? .updated : .duplicate
    }

    /// Adds one generated example to a saved slang item.
    func appendExample(_ example: SavedSlangExample, for id: UUID) -> SavedSlangExampleSaveResult {
        var items = loadItems()
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return .notFound
        }

        var item = items[index]
        item.examples = Array(item.examples.prefix(SavedSlangLimits.maximumExampleCount))

        guard item.examples.count < SavedSlangLimits.maximumExampleCount else {
            items[index] = item
            persistence.save(items)
            return .full
        }

        switch SavedSlangRules.appendUniqueExample(example, to: &item.examples) {
        case .saved:
            break
        case .duplicate:
            return .duplicate
        case .full:
            return .full
        case .invalid:
            return .invalid
        }

        items[index] = item
        persistence.save(items)
        return .saved(item)
    }

    /// Removes all locally saved slang items.
    func clear() {
        persistence.clear()
    }

    /// Removes one locally saved slang item by id.
    func delete(id: UUID) {
        let items = loadItems().filter { $0.id != id }
        persistence.save(items)
    }

    /// Removes one generated example from a saved slang item.
    func deleteExample(id exampleID: UUID, from slangID: UUID) -> SavedSlang? {
        var items = loadItems()
        guard let index = items.firstIndex(where: { $0.id == slangID }) else {
            return nil
        }

        var item = items[index]
        item.examples.removeAll { $0.id == exampleID }
        item.examples = Array(item.examples.prefix(SavedSlangLimits.maximumExampleCount))
        items[index] = item
        persistence.save(items)
        return item
    }
}
