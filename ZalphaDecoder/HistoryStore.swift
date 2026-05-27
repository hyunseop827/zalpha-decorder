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
            return try JSONDecoder().decode([HistoryItem].self, from: data)
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

    private func persist(_ items: [HistoryItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to save decode history:", error)
        }
    }
}
