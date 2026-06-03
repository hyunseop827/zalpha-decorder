//
//  DecodeLanguage.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

/// Supported language options shown in the source and target menus.
enum DecodeLanguage: CaseIterable {
    case auto
    case english
    case korean
    case japanese
    case spanish
    case russian

    var displayName: String {
        switch self {
        case .auto:
            return "Auto"
        case .english:
            return "English"
        case .korean:
            return "한국어"
        case .japanese:
            return "Japanese"
        case .spanish:
            return "Spanish"
        case .russian:
            return "Russian"
        }
    }

    var localizedDisplayName: String {
        switch self {
        case .auto:
            return AppStrings.Language.auto
        case .english:
            return AppStrings.Language.english
        case .korean:
            return AppStrings.Language.korean
        case .japanese:
            return AppStrings.Language.japanese
        case .spanish:
            return AppStrings.Language.spanish
        case .russian:
            return AppStrings.Language.russian
        }
    }

    static let sourceOptions: [DecodeLanguage] = [.auto, .english, .korean, .japanese, .spanish, .russian]
    static let targetOptions: [DecodeLanguage] = [.english, .korean, .japanese, .spanish, .russian]

    init?(storedName: String) {
        switch storedName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "auto":
            self = .auto
        case "english", "영어":
            self = .english
        case "korean", "한국어":
            self = .korean
        case "japanese", "일본어":
            self = .japanese
        case "spanish", "스페인어":
            self = .spanish
        case "russian", "러시아어":
            self = .russian
        default:
            return nil
        }
    }

    static func localizedDisplayName(for storedName: String) -> String {
        DecodeLanguage(storedName: storedName)?.localizedDisplayName ?? storedName
    }
}
