//
//  SavedSlangsViewController+Table.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Handles Saved Slangs table view data binding and row selection.
extension SavedSlangsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SavedSlangCell.reuseIdentifier,
            for: indexPath
        ) as? SavedSlangCell else {
            return UITableViewCell()
        }

        cell.configure(with: displayedItems[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedItem = displayedItems[indexPath.row]
        performSegue(withIdentifier: Self.savedSlangDetailSegueIdentifier, sender: self)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let item = displayedItems[indexPath.row]
        let copyAction = UIContextualAction(style: .normal, title: AppStrings.SavedSlang.copyAction) { [weak self] _, _, completion in
            self?.copyExpression(from: item)
            completion(true)
        }
        copyAction.backgroundColor = accentColor

        let deleteAction = UIContextualAction(style: .destructive, title: AppStrings.SavedSlang.deleteAction) { [weak self] _, _, completion in
            self?.confirmDelete(item)
            completion(false)
        }

        let configuration = UISwipeActionsConfiguration(actions: [deleteAction, copyAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }

    private func copyExpression(from item: SavedSlang) {
        UIPasteboard.general.string = item.sourceExpression
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast(AppStrings.SavedSlang.expressionCopied)
    }

    private func confirmDelete(_ item: SavedSlang) {
        let alertController = UIAlertController(
            title: AppStrings.SavedSlang.deleteTitle,
            message: "\"\(item.sourceExpression)\"",
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .destructive) { [weak self] _ in
            SavedSlangStore.shared.delete(id: item.id)
            self?.reloadSavedSlangs()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self?.showToast(AppStrings.SavedSlang.deleted)
        })
        present(alertController, animated: true)
    }
}
