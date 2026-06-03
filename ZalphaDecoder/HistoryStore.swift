//
//  HistoryStore.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

/// Saved local decode record shown in the History flow.
struct HistoryItem: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let sourceLanguage: String
    let targetLanguage: String
    let style: String
    let inputText: String
    let outputText: String
    let notes: [DecodeNote]
}

extension HistoryItem {
    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case sourceLanguage
        case targetLanguage
        case style
        case inputText
        case outputText
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        sourceLanguage = try container.decode(String.self, forKey: .sourceLanguage)
        targetLanguage = try container.decode(String.self, forKey: .targetLanguage)
        style = try container.decode(String.self, forKey: .style)
        inputText = try container.decode(String.self, forKey: .inputText)
        outputText = try container.decode(String.self, forKey: .outputText)

        // Older builds stored notes in different shapes. Keep the history row and drop
        // only its notes when that payload can no longer be decoded.
        if let decodedNotes = try? container.decode([DecodeNote].self, forKey: .notes) {
            notes = decodedNotes
        } else {
            notes = []
        }
    }
}

/// Small UserDefaults-backed store for recent local decode history.
final class HistoryStore {
    static let shared = HistoryStore()

    private let storageKey = "zalpha.decode.history.items"
    private let maximumItemCount = 50
    private let userDefaults: UserDefaults

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Loads saved history items in newest-first order.
    func loadItems() -> [HistoryItem] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder()
                .decode([LossyHistoryItem].self, from: data)
                .compactMap(\.item)
        } catch {
            print("Failed to load decode history:", error)
            return []
        }
    }

    /// Saves one history item and keeps only the most recent records.
    func save(_ item: HistoryItem) {
        var items = loadItems()
        items.insert(item, at: 0)
        items = Array(items.prefix(maximumItemCount))
        persist(items)
    }

    /// Removes all locally saved history.
    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }

    /// Removes one locally saved history item by id.
    func delete(id: UUID) {
        let items = loadItems().filter { $0.id != id }
        persist(items)
    }

    private func persist(_ items: [HistoryItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to save decode history:", error)
        }
    }
}

private struct LossyHistoryItem: Decodable {
    let item: HistoryItem?

    init(from decoder: Decoder) throws {
        // Skip only the malformed entry instead of making the whole History screen empty.
        item = try? HistoryItem(from: decoder)
    }
}
