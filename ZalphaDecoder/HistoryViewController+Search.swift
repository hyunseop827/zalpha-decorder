//
//  HistoryViewController+Search.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Handles local search for history records.
extension HistoryViewController: UISearchResultsUpdating {

    func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = AppStrings.History.searchPlaceholder
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    func updateSearchResults(for searchController: UISearchController) {
        applySearchFilter(searchController.searchBar.text)
        tableView.reloadData()
        updateBackgroundView()
    }

    func applySearchFilter(_ searchText: String?) {
        let query = searchText?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""

        guard !query.isEmpty else {
            filteredItems = []
            return
        }

        filteredItems = items.filter { item in
            let localizedStyle = TranslationStyle.localizedDisplayName(for: item.style).lowercased()

            return item.inputText.lowercased().contains(query)
                || item.outputText.lowercased().contains(query)
                || item.sourceLanguage.lowercased().contains(query)
                || item.targetLanguage.lowercased().contains(query)
                || item.style.lowercased().contains(query)
                || localizedStyle.contains(query)
        }
    }

    var isSearching: Bool {
        !(searchController.searchBar.text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ?? true)
    }

    var displayedItems: [HistoryItem] {
        isSearching ? filteredItems : items
    }
}
