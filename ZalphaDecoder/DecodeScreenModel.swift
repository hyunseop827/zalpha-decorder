//
//  DecodeScreenModel.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

/// Main decode screen state and state-only mutations.
final class DecodeScreenModel {
    var isDecoding = false
    var hasShownStartupSplash = false
    var emptyDecodeTapCount = 0
    var selectedStyle: TranslationStyle = .formal
    var sourceLanguage: DecodeLanguage = .auto
    var targetLanguage: DecodeLanguage = .english
    var latestHistoryItem: HistoryItem?

    func selectStyle(_ style: TranslationStyle) {
        selectedStyle = style
    }

    func setLanguage(_ language: DecodeLanguage, changesSource: Bool) {
        if changesSource {
            sourceLanguage = language
        } else {
            targetLanguage = language
        }
    }

    func swapLanguages() {
        if sourceLanguage == .auto {
            let previousTargetLanguage = targetLanguage
            sourceLanguage = previousTargetLanguage
            targetLanguage = previousTargetLanguage == .english ? .korean : .english
        } else {
            swap(&sourceLanguage, &targetLanguage)
        }
    }

    func resetEmptyDecodeTapCount() {
        emptyDecodeTapCount = 0
    }

    func nextEmptyDecodeMessage() -> String {
        emptyDecodeTapCount += 1

        guard emptyDecodeTapCount > 3 else {
            return DecodeMessage.emptyInputDefault
        }

        let index = (emptyDecodeTapCount - 4) % DecodeMessage.emptyInputVariants.count
        return DecodeMessage.emptyInputVariants[index]
    }

    func setDecoding(_ isDecoding: Bool) {
        self.isDecoding = isDecoding
    }

    func markStartupSplashShownIfNeeded() -> Bool {
        guard !hasShownStartupSplash else { return false }
        hasShownStartupSplash = true
        return true
    }

    func resolvedSourceLanguage(for input: String) -> DecodeLanguage? {
        InputLanguageDetector.resolvedSourceLanguage(for: input, sourceLanguage: sourceLanguage)
    }

    func sourceLanguageMismatchMessage(for input: String) -> String? {
        InputLanguageDetector.sourceLanguageMismatchMessage(for: input, sourceLanguage: sourceLanguage)
    }

    func recordHistoryItem(
        resolvedSourceLanguage: DecodeLanguage,
        inputText: String,
        decodeResult: DecodeResult,
        id: UUID = UUID(),
        createdAt: Date = Date()
    ) -> HistoryItem {
        let historyItem = HistoryItem(
            id: id,
            createdAt: createdAt,
            sourceLanguage: resolvedSourceLanguage.displayName,
            targetLanguage: targetLanguage.displayName,
            style: selectedStyle.displayName,
            inputText: inputText,
            outputText: decodeResult.result,
            notes: decodeResult.notes
        )
        latestHistoryItem = historyItem
        return historyItem
    }
}

enum DecodeMessage {
    static let emptyInputDefault = AppStrings.Decode.emptyInputDefault
    static let safetyBlocked = AppStrings.Decode.safetyBlocked
    static let rateLimited = AppStrings.Decode.rateLimited
    static let networkUnavailable = AppStrings.Decode.networkUnavailable
    static let aiUnavailable = AppStrings.Decode.aiUnavailable
    static let genericError = AppStrings.Decode.genericError

    static let emptyInputVariants = [
        AppStrings.localized("decode.empty.variant.01"),
        AppStrings.localized("decode.empty.variant.02"),
        AppStrings.localized("decode.empty.variant.03"),
        AppStrings.localized("decode.empty.variant.04"),
        AppStrings.localized("decode.empty.variant.05"),
        AppStrings.localized("decode.empty.variant.06"),
        AppStrings.localized("decode.empty.variant.07"),
        AppStrings.localized("decode.empty.variant.08"),
        AppStrings.localized("decode.empty.variant.09"),
        AppStrings.localized("decode.empty.variant.10"),
        AppStrings.localized("decode.empty.variant.11"),
        AppStrings.localized("decode.empty.variant.12"),
        AppStrings.localized("decode.empty.variant.13"),
        AppStrings.localized("decode.empty.variant.14"),
        AppStrings.localized("decode.empty.variant.15"),
        AppStrings.localized("decode.empty.variant.16"),
        AppStrings.localized("decode.empty.variant.17"),
        AppStrings.localized("decode.empty.variant.18"),
        AppStrings.localized("decode.empty.variant.19"),
        AppStrings.localized("decode.empty.variant.20")
    ]
}
