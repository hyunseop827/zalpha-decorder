//
//  SavedSlangsViewController+Actions.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Handles navigation-level actions for the saved slang list.
extension SavedSlangsViewController {
    func configureNavigationActions() {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(confirmDeleteAllSavedSlangs)
        )
        button.tintColor = .systemRed
        deleteAllButton = button
        navigationItem.rightBarButtonItem = button
        updateDeleteAllSavedSlangsButton()
    }

    func updateDeleteAllSavedSlangsButton() {
        deleteAllButton?.isEnabled = !items.isEmpty
    }

    @objc private func confirmDeleteAllSavedSlangs() {
        guard !items.isEmpty else { return }

        let alertController = UIAlertController(
            title: AppStrings.SavedSlang.deleteAllTitle,
            message: AppStrings.SavedSlang.deleteAllMessage,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .destructive) { [weak self] _ in
            SavedSlangStore.shared.clear()
            self?.reloadSavedSlangs()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self?.showToast(AppStrings.SavedSlang.allDeleted)
        })
        present(alertController, animated: true)
    }
}
