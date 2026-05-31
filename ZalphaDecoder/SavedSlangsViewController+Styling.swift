//
//  SavedSlangsViewController+Styling.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Groups runtime styling for the storyboard-backed Saved Slangs list.
extension SavedSlangsViewController {

    func configureTableView() {
        configureDynamicColors()
        tableView.dataSource = self
        tableView.delegate = self
    }

    func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: SavedSlangsViewController, _) in
            viewController.configureDynamicColors()
            viewController.tableView.reloadData()
        }
    }

    func configureDynamicColors() {
        view.backgroundColor = AppTheme.pageBackgroundColor
        toastLabel?.backgroundColor = AppTheme.toastBackgroundColor
        toastLabel?.textColor = AppTheme.toastTextColor
    }

    func updateBackgroundView() {
        guard displayedItems.isEmpty else {
            tableView.backgroundView = nil
            return
        }

        let label = UILabel()
        label.text = isSearching ? AppStrings.SavedSlang.noMatching : AppStrings.SavedSlang.noSaved
        label.textColor = AppTheme.secondaryLabelColor
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        tableView.backgroundView = label
    }

    var accentColor: UIColor {
        AppTheme.accentColor
    }
}
