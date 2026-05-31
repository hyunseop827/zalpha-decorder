//
//  SavedSlangDetailViewController+Actions.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Handles user actions for copying examples or deleting one saved slang item.
extension SavedSlangDetailViewController {

    @IBAction func copyExpressionButtonTapped(_ sender: Any) {
        guard let expression = item?.sourceExpression, !expression.isEmpty else { return }

        UIPasteboard.general.string = expression
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast(AppStrings.SavedSlang.expressionCopied)
    }

    @objc func copyExampleButtonTapped(_ sender: UIButton) {
        guard exampleCopyTexts.indices.contains(sender.tag) else { return }

        UIPasteboard.general.string = exampleCopyTexts[sender.tag]
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast(AppStrings.SavedSlang.exampleCopied)
    }

    @IBAction func deleteSlangButtonTapped(_ sender: UIBarButtonItem) {
        guard let item else { return }

        let alertController = UIAlertController(
            title: AppStrings.SavedSlang.deleteTitle,
            message: "\"\(item.sourceExpression)\"",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .destructive) { [weak self] _ in
            self?.deleteAndReturnToList(item)
        })
        present(alertController, animated: true)
    }

    private func deleteAndReturnToList(_ item: SavedSlang) {
        SavedSlangStore.shared.delete(id: item.id)
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        let listViewController = navigationController?.viewControllers
            .dropLast()
            .last as? SavedSlangsViewController
        navigationController?.popViewController(animated: true)
        listViewController?.reloadSavedSlangs()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            listViewController?.showToast(AppStrings.SavedSlang.deleted)
        }
    }
}
