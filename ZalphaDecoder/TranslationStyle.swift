//
//  TranslationStyle.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

/// Output tone options shared by the style buttons and AI prompt.
enum TranslationStyle {
    case formal
    case plain
    case casual
    case genZalpha

    var displayName: String {
        switch self {
        case .formal:
            return "Formal"
        case .plain:
            return "Plain"
        case .casual:
            return "Casual"
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
        case .casual:
            return AppStrings.Main.casualStyle
        case .genZalpha:
            return AppStrings.Main.zalphaStyle
        }
    }
}
