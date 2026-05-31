//
//  InputLanguageDetector.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import NaturalLanguage

/// Detects supported input languages for Auto mode and explicit-source mismatch checks.
enum InputLanguageDetector {

    /// Returns the explicit source language or detects one when source is Auto.
    static func resolvedSourceLanguage(for input: String, sourceLanguage: DecodeLanguage) -> DecodeLanguage? {
        guard sourceLanguage == .auto else {
            return sourceLanguage
        }

        return detectInputLanguage(input)
    }

    /// Returns a warning message when explicit source language clearly conflicts with the input.
    static func sourceLanguageMismatchMessage(for input: String, sourceLanguage: DecodeLanguage) -> String? {
        guard sourceLanguage != .auto, shouldCheckExplicitSource(for: input) else {
            return nil
        }
        guard let detectedLanguage = detectInputLanguage(input), detectedLanguage != sourceLanguage else {
            return nil
        }

        return AppStrings.Decode.sourceLanguageMismatch(detectedLanguage.localizedDisplayName)
    }

    /// Detects supported languages using script counts first, then NaturalLanguage as fallback.
    static func detectInputLanguage(_ input: String) -> DecodeLanguage? {
        let counts = scriptCounts(in: input)

        if counts.hangul > 0,
           counts.kana == 0,
           counts.cyrillic == 0,
           counts.latin == 0 {
            return .korean
        }
        if counts.kana > 0,
           counts.hangul == 0,
           counts.cyrillic == 0 {
            return .japanese
        }
        if counts.cyrillic > 0,
           counts.hangul == 0,
           counts.kana == 0,
           counts.latin == 0 {
            return .russian
        }
        if counts.hangul >= 2,
           counts.hangul >= counts.latin * 2,
           counts.hangul >= counts.kana * 2,
           counts.hangul >= counts.cyrillic * 2 {
            return .korean
        }
        if counts.kana >= 2,
           counts.kana >= counts.hangul,
           counts.kana >= counts.cyrillic {
            return .japanese
        }
        if counts.cyrillic >= 2,
           counts.cyrillic >= counts.hangul * 2,
           counts.cyrillic >= counts.kana * 2,
           counts.cyrillic >= counts.latin * 2 {
            return .russian
        }

        let recognizer = NLLanguageRecognizer()
        recognizer.processString(input)
        let hypotheses = recognizer.languageHypotheses(withMaximum: 4)

        if (hypotheses[.korean] ?? 0) >= 0.7 {
            return .korean
        }
        if (hypotheses[.japanese] ?? 0) >= 0.7 {
            return .japanese
        }
        if (hypotheses[.russian] ?? 0) >= 0.7 {
            return .russian
        }
        if counts.latin >= 4 {
            if (hypotheses[.spanish] ?? 0) >= 0.78 {
                return .spanish
            }
            if (hypotheses[.english] ?? 0) >= 0.72 {
                return .english
            }
        }

        return nil
    }

    /// Skips mismatch checks for very short or ambiguous input.
    private static func shouldCheckExplicitSource(for input: String) -> Bool {
        let counts = scriptCounts(in: input)
        let strongScriptCount = counts.hangul + counts.kana + counts.cyrillic

        if strongScriptCount >= 4 {
            return true
        }

        return counts.latin >= 12
    }

    /// Counts script families so short mixed input can be handled predictably.
    private static func scriptCounts(in input: String) -> (hangul: Int, kana: Int, cyrillic: Int, latin: Int) {
        input.unicodeScalars.reduce(into: (hangul: 0, kana: 0, cyrillic: 0, latin: 0)) { counts, scalar in
            if isHangul(scalar) {
                counts.hangul += 1
            } else if isKana(scalar) {
                counts.kana += 1
            } else if isCyrillic(scalar) {
                counts.cyrillic += 1
            } else if isLatinLetter(scalar) {
                counts.latin += 1
            }
        }
    }

    /// Checks whether a Unicode scalar belongs to Korean Hangul blocks.
    private static func isHangul(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x1100...0x11FF, 0x3130...0x318F, 0xAC00...0xD7AF, 0xA960...0xA97F, 0xD7B0...0xD7FF:
            return true
        default:
            return false
        }
    }

    /// Checks whether a Unicode scalar belongs to Japanese Hiragana or Katakana blocks.
    private static func isKana(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x3040...0x309F, 0x30A0...0x30FF, 0x31F0...0x31FF, 0xFF66...0xFF9F:
            return true
        default:
            return false
        }
    }

    /// Checks whether a Unicode scalar belongs to Cyrillic blocks used by Russian.
    private static func isCyrillic(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0400...0x052F, 0x2DE0...0x2DFF, 0xA640...0xA69F:
            return true
        default:
            return false
        }
    }

    /// Checks whether a Unicode scalar is a Latin alphabet letter.
    private static func isLatinLetter(_ scalar: UnicodeScalar) -> Bool {
        switch scalar.value {
        case 0x0041...0x005A, 0x0061...0x007A, 0x00C0...0x024F:
            return true
        default:
            return false
        }
    }
}
