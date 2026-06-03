//
//  TranslationStyle.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

/// Output tone options shared by the style buttons and AI prompt.
enum TranslationStyle {
    case formal
    case plain
    case genZalpha

    init?(storedName: String) {
        switch storedName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "formal", "격식":
            self = .formal
        case "plain", "기본", "casual", "캐주얼":
            self = .plain
        case "zalpha", "gen zalpha", "잘파":
            self = .genZalpha
        default:
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .formal:
            return "Formal"
        case .plain:
            return "Plain"
        case .genZalpha:
            return "Zalpha"
        }
    }

    var localizedDisplayName: String {
        switch self {
        case .formal:
            return AppStrings.Main.formalStyle
        case .plain:
            return AppStrings.Main.plainStyle
        case .genZalpha:
            return AppStrings.Main.zalphaStyle
        }
    }

    static func localizedDisplayName(for storedName: String) -> String {
        TranslationStyle(storedName: storedName)?.localizedDisplayName ?? storedName
    }
}
