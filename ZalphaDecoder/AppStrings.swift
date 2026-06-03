//
//  AppStrings.swift
//  ZalphaDecoder
//

import Foundation

/// Runtime strings backed by `Localizable.strings`.
enum AppStrings {
    static var dateLocale: Locale {
        Locale(identifier: localized("date.locale.identifier"))
    }

    static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: localized(key), locale: dateLocale, arguments: arguments)
    }

    enum Common {
        static let yes = AppStrings.localized("common.yes")
        static let no = AppStrings.localized("common.no")
    }

    enum Main {
        static let title = AppStrings.localized("main.title")
        static let style = AppStrings.localized("main.style")
        static let decodeButton = AppStrings.localized("main.decodeButton")
        static let notesTitle = AppStrings.localized("main.notes.title")
        static let outputCopied = AppStrings.localized("main.output.copied")
        static let noCurrentDecode = AppStrings.localized("main.notes.noCurrentDecode")
        static let formalStyle = AppStrings.localized("main.style.formal")
        static let plainStyle = AppStrings.localized("main.style.plain")
        static let zalphaStyle = AppStrings.localized("main.style.zalpha")

        static func inputTitle(_ language: String) -> String {
            AppStrings.format("main.input.title", language)
        }

        static func outputTitle(_ language: String) -> String {
            AppStrings.format("main.output.title", language)
        }
    }

    enum Decode {
        static let emptyInputDefault = AppStrings.localized("decode.empty.default")
        static let safetyBlocked = AppStrings.localized("decode.error.blocked")
        static let rateLimited = AppStrings.localized("decode.error.rateLimited")
        static let networkUnavailable = AppStrings.localized("decode.error.network")
        static let aiUnavailable = AppStrings.localized("decode.error.aiUnavailable")
        static let genericError = AppStrings.localized("decode.error.generic")
        static let couldNotDetectLanguage = AppStrings.localized("decode.error.detectLanguage")
        static let loadingTitle = AppStrings.localized("decode.loading.title")
        static let notesDetailAccessibilityLabel = AppStrings.localized("decode.notes.detail.accessibility")
        static let noteLanguage = AppStrings.localized("decode.note.language")

        static func sourceLanguageMismatch(_ language: String) -> String {
            AppStrings.format("decode.error.sourceMismatch", language)
        }

    }

    enum History {
        static let title = AppStrings.localized("history.title")
        static let detailTitle = AppStrings.localized("history.detail.title")
        static let noHistory = AppStrings.localized("history.empty")
        static let deleteAction = AppStrings.localized("history.action.delete")
        static let deleteAllTitle = AppStrings.localized("history.deleteAll.title")
        static let deleteOneTitle = AppStrings.localized("history.deleteOne.title")
        static let deleteMessage = AppStrings.localized("history.delete.message")
        static let deleted = AppStrings.localized("history.deleted")
        static let input = AppStrings.localized("history.input")
        static let output = AppStrings.localized("history.output")
        static let noItemSelected = AppStrings.localized("history.detail.noItem")
        static let noNotes = AppStrings.localized("history.detail.noNotes")
        static let expression = AppStrings.localized("history.note.expression")
        static let meaning = AppStrings.localized("history.note.meaning")
        static let originalExpression = AppStrings.localized("history.note.originalExpression")
        static let save = AppStrings.localized("history.note.save")
        static let saveTitle = AppStrings.localized("history.note.saveTitle")
        static let saveAll = AppStrings.localized("history.note.saveAll")
        static let saveAllTitle = AppStrings.localized("history.note.saveAllTitle")
        static let searchPlaceholder = AppStrings.localized("history.search.placeholder")
        static let noMatching = AppStrings.localized("history.empty.noMatching")

        static func inputTitle(_ language: String) -> String {
            AppStrings.format("history.input.language", language)
        }

        static func outputTitle(_ language: String) -> String {
            AppStrings.format("history.output.language", language)
        }

        static func savedAndUpdatedNotes(savedCount: Int, updatedCount: Int) -> String {
            AppStrings.format("history.note.saveAll.savedAndUpdated", savedCount, updatedCount)
        }

        static func savedNotes(_ count: Int) -> String {
            AppStrings.format("history.note.saveAll.saved", count)
        }

        static func updatedNotes(_ count: Int) -> String {
            AppStrings.format("history.note.saveAll.updated", count)
        }
    }

    enum SavedSlang {
        static let title = AppStrings.localized("savedSlang.title")
        static let detailTitle = AppStrings.localized("savedSlang.detail.title")
        static let saved = AppStrings.localized("savedSlang.result.saved")
        static let updated = AppStrings.localized("savedSlang.result.updated")
        static let duplicate = AppStrings.localized("savedSlang.result.duplicate")
        static let invalid = AppStrings.localized("savedSlang.result.invalid")
        static let exampleAdded = AppStrings.localized("savedSlang.example.added")
        static let exampleDuplicate = AppStrings.localized("savedSlang.example.duplicate")
        static let exampleFull = AppStrings.localized("savedSlang.example.full")
        static let exampleInvalid = AppStrings.localized("savedSlang.example.invalid")
        static let generateExample = AppStrings.localized("savedSlang.example.generate")
        static let meaningsTitle = AppStrings.localized("savedSlang.meanings.title")
        static let noMeanings = AppStrings.localized("savedSlang.noMeanings")
        static let examplesTitle = AppStrings.localized("savedSlang.examples.title")
        static let examplesLoadingTitle = AppStrings.localized("savedSlang.examples.loading")
        static let examplesBlocked = AppStrings.localized("savedSlang.examples.error.blocked")
        static let examplesGeneric = AppStrings.localized("savedSlang.examples.error.generic")
        static let exampleDeleted = AppStrings.localized("savedSlang.example.deleted")
        static let couldNotDeleteExample = AppStrings.localized("savedSlang.example.deleteFailed")
        static let expressionCopied = AppStrings.localized("savedSlang.expression.copied")
        static let exampleCopied = AppStrings.localized("savedSlang.example.copied")
        static let deleteTitle = AppStrings.localized("savedSlang.delete.title")
        static let deleteAllTitle = AppStrings.localized("savedSlang.deleteAll.title")
        static let deleteAllMessage = AppStrings.localized("savedSlang.deleteAll.message")
        static let deleted = AppStrings.localized("savedSlang.deleted")
        static let allDeleted = AppStrings.localized("savedSlang.allDeleted")
        static let copyAction = AppStrings.localized("savedSlang.action.copy")
        static let deleteAction = AppStrings.localized("savedSlang.action.delete")
        static let noExamples = AppStrings.localized("savedSlang.examples.empty")
        static let noSaved = AppStrings.localized("savedSlang.empty.noSaved")
        static let noMatching = AppStrings.localized("savedSlang.empty.noMatching")
        static let searchPlaceholder = AppStrings.localized("savedSlang.search.placeholder")

        static func metadata(expressionLanguage: String, meaningLanguage: String, date: String) -> String {
            AppStrings.format("savedSlang.metadata.updated", expressionLanguage, meaningLanguage, date)
        }

        static func meaningPreview(_ meaning: String) -> String {
            guard !meaning.isEmpty else {
                return AppStrings.localized("savedSlang.meaning.preview.empty")
            }

            return AppStrings.format("savedSlang.meaning.preview", meaning)
        }
    }

    enum Language {
        static let auto = AppStrings.localized("language.auto")
        static let english = AppStrings.localized("language.english")
        static let korean = AppStrings.localized("language.korean")
        static let japanese = AppStrings.localized("language.japanese")
        static let spanish = AppStrings.localized("language.spanish")
        static let russian = AppStrings.localized("language.russian")
    }
}

extension AppStrings.Decode {
    static func noteLine(
        originalExpression: String,
        meaning: String,
        meaningLanguage: String,
        expression: String
    ) -> String {
        guard !expression.isEmpty else {
            return AppStrings.format("decode.note.line.noTranslation", originalExpression, meaning)
        }

        return AppStrings.format("decode.note.line", originalExpression, expression)
    }
}
