//
//  HistoryViewController+Styling.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Groups runtime styling for the storyboard-backed History list.
extension HistoryViewController {

    func configureTableView() {
        configureDynamicColors()
        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: HistoryViewController, _) in
            viewController.configureDynamicColors()
            viewController.tableView.reloadData()
        }
    }

    func configureDynamicColors() {
        view.backgroundColor = AppTheme.pageBackgroundColor
    }

    func updateDeleteAllButtonState() {
        deleteAllHistoryButton?.isEnabled = !items.isEmpty
    }

    func updateBackgroundView() {
        guard displayedItems.isEmpty else {
            tableView.backgroundView = nil
            return
        }

        let label = UILabel()
        label.text = isSearching ? AppStrings.History.noMatching : AppStrings.History.noHistory
        label.textColor = AppTheme.secondaryLabelColor
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        tableView.backgroundView = label
    }
}
