//
//  ViewController+Decode.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Coordinates Decode button flow, including validation, language resolution, AI calls, and loading state.
extension ViewController {

    /// Validates input, resolves language settings, calls AIService, and writes the result to the output box.
    @MainActor
    func runDecode() async {
        let input = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            showToast(nextEmptyDecodeMessage())
            return
        }

        if let mismatchMessage = sourceLanguageMismatchMessage(for: input) {
            showToast(mismatchMessage)
            return
        }

        guard let resolvedSourceLanguage = resolvedSourceLanguage(for: input) else {
            showToast("Could not detect input language.")
            return
        }

        emptyDecodeTapCount = 0
        setDecodeLoading(true)
        defer {
            setDecodeLoading(false)
        }

        do {
            outputTextView.text = try await aiService.decode(
                text: input,
                sourceLanguage: resolvedSourceLanguage.displayName,
                targetLanguage: targetLanguage.displayName,
                style: selectedStyle
            )
        } catch AIServiceError.blocked {
            print("Firebase AI Logic decode blocked by safety filters.")
            showToast(DecodeMessage.safetyBlocked)
        } catch AIServiceError.rateLimited {
            print("Firebase AI Logic decode rate limited.")
            showToast(DecodeMessage.rateLimited)
        } catch AIServiceError.emptyResponse {
            print("Firebase AI Logic decode returned an empty response.")
            showToast(DecodeMessage.genericError)
        } catch {
            print("Firebase AI Logic decode failed:", error)
            showToast(DecodeMessage.genericError)
        }
    }

    /// Updates the Decode button while a Gemini request is in progress.
    @MainActor
    func setDecodeLoading(_ isLoading: Bool) {
        isDecoding = isLoading
        decodeButton.isEnabled = !isLoading
        decodeButton.alpha = isLoading ? 0.78 : 1.0
        let title = isLoading ? "Decoding..." : "Decode"
        decodeButton.setTitle(title, for: .normal)
        decodeButton.setTitle(title, for: .disabled)
        decodeButton.setTitleColor(.white, for: .normal)
        decodeButton.setTitleColor(UIColor.white.withAlphaComponent(0.86), for: .disabled)
    }

    /// Returns the next empty-input toast message based on repeated empty Decode taps.
    private func nextEmptyDecodeMessage() -> String {
        emptyDecodeTapCount += 1

        guard emptyDecodeTapCount > 3 else {
            return DecodeMessage.emptyInputDefault
        }

        let index = (emptyDecodeTapCount - 4) % DecodeMessage.emptyInputVariants.count
        return DecodeMessage.emptyInputVariants[index]
    }
}

private enum DecodeMessage {
    static let emptyInputDefault = "Enter text to decode."
    static let safetyBlocked = "This text was blocked by safety filters."
    static let rateLimited = "Rate limit reached. Try again soon."
    static let genericError = "Could not decode. Try again."

    static let emptyInputVariants = [
        "Bro, it's empty.",
        "There is nothing to decode.",
        "Bro, this ain't tuff. 🥀",
        "No text? We are cooked.",
        "Is bro okay?",
        "Type something plz 🙏",
        "No words, no decode.",
        "Skibidi Toilet",
        "I mog you btw...",
        "Messi or Ronaldo ???",
        "Zalpha needs actual text, bro.",
        "Idc at this moment",
        "This is sub3 behavior",
        "Never expected someone doing this",
        "you win bro",
        "go sleep plz",
        "Enter text to decode.",
        "Enter text to decode.",
        "Enter text to decode.",
        "touch grass plz"
    ]
}
