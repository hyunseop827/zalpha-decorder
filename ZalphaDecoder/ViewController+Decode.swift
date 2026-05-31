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
            showToast(screenModel.nextEmptyDecodeMessage())
            return
        }

        if let mismatchMessage = sourceLanguageMismatchMessage(for: input) {
            showToast(mismatchMessage)
            return
        }

        guard let resolvedSourceLanguage = resolvedSourceLanguage(for: input) else {
            showToast(AppStrings.Decode.couldNotDetectLanguage)
            return
        }

        screenModel.resetEmptyDecodeTapCount()
        setDecodeLoading(true)
        defer {
            setDecodeLoading(false)
        }

        do {
            let decodeResult = try await aiService.decode(
                text: input,
                sourceLanguage: resolvedSourceLanguage.displayName,
                targetLanguage: screenModel.targetLanguage.displayName,
                style: screenModel.selectedStyle
            )
            outputTextView.text = decodeResult.result
            notesBodyLabel.attributedText = formattedNotes(decodeResult.notes)
            let historyItem = screenModel.recordHistoryItem(
                resolvedSourceLanguage: resolvedSourceLanguage,
                inputText: input,
                decodeResult: decodeResult
            )
            HistoryStore.shared.save(historyItem)
        } catch AIServiceError.blocked {
            print("Firebase AI Logic decode blocked by safety filters.")
            showToast(DecodeMessage.safetyBlocked)
        } catch AIServiceError.rateLimited {
            print("Firebase AI Logic decode rate limited.")
            showToast(DecodeMessage.rateLimited)
        } catch AIServiceError.networkUnavailable {
            print("Firebase AI Logic decode failed because the network is unavailable.")
            showToast(DecodeMessage.networkUnavailable)
        } catch AIServiceError.serviceUnavailable {
            print("Firebase AI Logic decode service unavailable.")
            showToast(DecodeMessage.aiUnavailable)
        } catch AIServiceError.configuration {
            print("Firebase AI Logic decode configuration error.")
            showToast(DecodeMessage.aiUnavailable)
        } catch AIServiceError.emptyResponse {
            print("Firebase AI Logic decode returned an empty response.")
            showToast(DecodeMessage.genericError)
        } catch AIServiceError.invalidResponse {
            print("Firebase AI Logic decode returned invalid JSON.")
            showToast(DecodeMessage.genericError)
        } catch {
            print("Firebase AI Logic decode failed:", error)
            showToast(DecodeMessage.genericError)
        }
    }

    /// Shows or hides the blocking loading overlay while a Gemini request is in progress.
    @MainActor
    func setDecodeLoading(_ isLoading: Bool) {
        screenModel.setDecoding(isLoading)
        decodeButton.isEnabled = !isLoading
        decodeButton.alpha = isLoading ? 0.78 : 1.0
        navigationItem.leftBarButtonItem?.isEnabled = !isLoading
        navigationItem.rightBarButtonItem?.isEnabled = !isLoading

        if isLoading {
            view.bringSubviewToFront(loadingOverlayView)
            loadingOverlayView.isHidden = false
            loadingActivityIndicator.startAnimating()
            UIView.animate(withDuration: 0.16) {
                self.loadingOverlayView.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.16) {
                self.loadingOverlayView.alpha = 0
            } completion: { _ in
                self.loadingActivityIndicator.stopAnimating()
                self.loadingOverlayView.isHidden = true
            }
        }
    }

    /// Formats short Decode Notes as spaced bullets for the notes card.
    private func formattedNotes(_ notes: [DecodeNote]) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        paragraphStyle.paragraphSpacing = 7

        let text = notes
            .prefix(5)
            .filter { !$0.sourceExpression.isEmpty && !$0.meaning.isEmpty }
            .map { note in
                AppStrings.Decode.noteLine(
                    sourceExpression: note.sourceExpression,
                    meaning: note.meaning,
                    translatedExpression: note.translatedExpression
                )
            }
            .joined(separator: "\n")

        return NSAttributedString(
            string: text,
            attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .paragraphStyle: paragraphStyle
            ]
        )
    }
}
