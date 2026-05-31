//
//  HistoryViewController+Actions.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Handles destructive History actions.
extension HistoryViewController {

    @IBAction func deleteAllHistoryButtonTapped(_ sender: UIBarButtonItem) {
        guard !items.isEmpty else { return }

        let alertController = UIAlertController(
            title: AppStrings.History.deleteAllTitle,
            message: AppStrings.History.deleteMessage,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .destructive) { [weak self] _ in
            HistoryStore.shared.clear()
            self?.reloadHistory()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
        present(alertController, animated: true)
    }

    func confirmDelete(_ item: HistoryItem) {
        let alertController = UIAlertController(
            title: AppStrings.History.deleteOneTitle,
            message: "\"\(item.inputText)\"",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .destructive) { [weak self] _ in
            HistoryStore.shared.delete(id: item.id)
            self?.reloadHistory()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        })
        present(alertController, animated: true)
    }
}
