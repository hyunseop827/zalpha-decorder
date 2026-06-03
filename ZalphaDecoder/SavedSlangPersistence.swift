//
//  SavedSlangPersistence.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

struct SavedSlangPersistence {
    private let storageKey = "zalpha.saved.slangs.items"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadItems() -> [SavedSlang] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            let items = try JSONDecoder().decode(LossySavedSlangArray.self, from: data).items
            return items.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            print("Failed to load saved slangs:", error)
            return []
        }
    }

    func save(_ items: [SavedSlang]) {
        do {
            let data = try JSONEncoder().encode(items.sorted { $0.updatedAt > $1.updatedAt })
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("Failed to save slangs:", error)
        }
    }

    func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}

private struct LossySavedSlangArray: Decodable {
    let items: [SavedSlang]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var decodedItems: [SavedSlang] = []

        while !container.isAtEnd {
            do {
                decodedItems.append(try container.decode(SavedSlang.self))
            } catch {
                // Saved slang fields changed during local-only development. One stale
                // record should not prevent the rest of the vocabulary from loading.
                print("Skipped one invalid saved slang item:", error)
                _ = try? container.decode(DiscardedSavedSlangValue.self)
            }
        }

        items = decodedItems
    }
}

private struct DiscardedSavedSlangValue: Decodable {
    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), container.decodeNil() {
            return
        }

        if var container = try? decoder.unkeyedContainer() {
            while !container.isAtEnd {
                _ = try? container.decode(DiscardedSavedSlangValue.self)
            }
            return
        }

        if let container = try? decoder.container(keyedBy: DynamicCodingKey.self) {
            for key in container.allKeys {
                _ = try? container.decode(DiscardedSavedSlangValue.self, forKey: key)
            }
        }
    }
}

private struct DynamicCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        intValue = nil
    }

    init?(intValue: Int) {
        stringValue = "\(intValue)"
        self.intValue = intValue
    }
}
