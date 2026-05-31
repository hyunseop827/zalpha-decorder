//
//  SavedSlangResults.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

/// Result of saving a Decode Note into the saved slang list.
enum SavedSlangSaveResult {
    case saved
    case updated
    case duplicate
    case invalid

    var message: String {
        switch self {
        case .saved:
            return AppStrings.SavedSlang.saved
        case .updated:
            return AppStrings.SavedSlang.updated
        case .duplicate:
            return AppStrings.SavedSlang.duplicate
        case .invalid:
            return AppStrings.SavedSlang.invalid
        }
    }
}

/// Result of adding one generated example to a saved slang item.
enum SavedSlangExampleSaveResult {
    case saved(SavedSlang)
    case duplicate
    case full
    case invalid
    case notFound

    var message: String {
        switch self {
        case .saved:
            return AppStrings.SavedSlang.exampleAdded
        case .duplicate:
            return AppStrings.SavedSlang.exampleDuplicate
        case .full:
            return AppStrings.SavedSlang.exampleFull
        case .invalid, .notFound:
            return AppStrings.SavedSlang.exampleInvalid
        }
    }
}
