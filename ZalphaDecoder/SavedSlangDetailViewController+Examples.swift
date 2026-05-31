//
//  SavedSlangDetailViewController+Examples.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Coordinates on-demand example generation for saved slang detail.
extension SavedSlangDetailViewController {

    @IBAction func generateExamplesButtonTapped(_ sender: UIButton) {
        guard !isGeneratingExamples else { return }
        guard let item else { return }

        guard item.examples.count < SavedSlangLimits.maximumExampleCount else {
            showToast("Delete an example first.")
            return
        }

        Task {
            await generateExample()
        }
    }

    @MainActor
    private func generateExample() async {
        guard let item else { return }
        guard item.examples.count < SavedSlangLimits.maximumExampleCount else {
            showToast("Delete an example first.")
            return
        }

        setExamplesLoading(true)
        defer {
            setExamplesLoading(false)
        }

        do {
            let generatedExample = try await aiService.generateExample(
                expression: item.sourceExpression,
                meaning: item.meanings.first ?? "",
                sourceLanguage: item.sourceLanguage,
                meaningLanguage: item.meaningLanguage,
                existingExamples: item.examples.map(\.sentence)
            )
            let savedExample = SavedSlangExample(
                id: UUID(),
                sentence: generatedExample.sentence,
                meaning: generatedExample.meaning,
                createdAt: Date()
            )

            let saveResult = SavedSlangStore.shared.appendExample(savedExample, for: item.id)
            guard case let .saved(updatedItem) = saveResult else {
                showToast(saveResult.message)
                return
            }

            self.item = updatedItem
            renderItem()

            UINotificationFeedbackGenerator().notificationOccurred(.success)
            showToast(saveResult.message)
        } catch AIServiceError.blocked {
            print("Firebase AI Logic example generation blocked by safety filters.")
            showToast("Examples could not be generated safely.")
        } catch AIServiceError.rateLimited {
            print("Firebase AI Logic example generation rate limited.")
            showToast("Too many requests. Try again soon.")
        } catch AIServiceError.networkUnavailable {
            print("Firebase AI Logic example generation failed because the network is unavailable.")
            showToast("Check your connection and try again.")
        } catch AIServiceError.serviceUnavailable, AIServiceError.configuration {
            print("Firebase AI Logic example generation unavailable.")
            showToast("AI is temporarily unavailable.")
        } catch {
            print("Firebase AI Logic example generation failed:", error)
            showToast("Could not generate examples.")
        }
    }

    @objc func deleteExampleButtonTapped(_ sender: UIButton) {
        guard let item, exampleIDs.indices.contains(sender.tag) else { return }
        guard let updatedItem = SavedSlangStore.shared.deleteExample(id: exampleIDs[sender.tag], from: item.id) else {
            showToast("Could not delete example.")
            return
        }

        self.item = updatedItem
        renderItem()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Example deleted.")
    }

    @MainActor
    private func setExamplesLoading(_ isLoading: Bool) {
        isGeneratingExamples = isLoading
        generateExamplesButton.isEnabled = !isLoading
        generateExamplesButton.alpha = isLoading ? 0.65 : 1
        navigationItem.rightBarButtonItems?.forEach {
            $0.isEnabled = !isLoading
        }

        if isLoading {
            view.bringSubviewToFront(examplesLoadingOverlayView)
            examplesLoadingOverlayView.isHidden = false
            examplesLoadingIndicator.startAnimating()
            UIView.animate(withDuration: 0.16) {
                self.examplesLoadingOverlayView.alpha = 1
            }
        } else {
            UIView.animate(withDuration: 0.16) {
                self.examplesLoadingOverlayView.alpha = 0
            } completion: { _ in
                self.examplesLoadingIndicator.stopAnimating()
                self.examplesLoadingOverlayView.isHidden = true
            }
        }
    }
}
