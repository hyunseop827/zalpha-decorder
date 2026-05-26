//
//  ViewController+AI.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

extension ViewController {

    @MainActor
    func runGreetingDecode() async {
        let input = inputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            showToast(nextEmptyDecodeMessage())
            return
        }

        emptyDecodeTapCount = 0
        setDecodeLoading(true)
        defer {
            setDecodeLoading(false)
        }

        do {
            outputTextView.text = try await aiService.generateGreeting()
        } catch {
            print("Firebase AI Logic decode failed:", error)
            showToast("Could not decode. Try again.")
        }
    }

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

    private func nextEmptyDecodeMessage() -> String {
        emptyDecodeTapCount += 1

        guard emptyDecodeTapCount > 3 else {
            return "Enter text to decode."
        }

        let messages = [
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
            "This is sub3 behavior"
        ]
        let index = (emptyDecodeTapCount - 4) % messages.count
        return messages[index]
    }
}
