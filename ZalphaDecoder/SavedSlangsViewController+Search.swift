//
//  SavedSlangsViewController+Search.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Handles local search for saved slang records.
extension SavedSlangsViewController: UISearchResultsUpdating {

    func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = AppStrings.SavedSlang.searchPlaceholder
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
            item.sourceExpression.lowercased().contains(query)
                || item.sourceLanguage.lowercased().contains(query)
                || item.meaningLanguage.lowercased().contains(query)
                || item.meanings.contains { $0.lowercased().contains(query) }
                || item.translatedExpressions.contains { $0.lowercased().contains(query) }
                || item.examples.contains {
                    $0.sentence.lowercased().contains(query) || $0.meaning.lowercased().contains(query)
                }
        }
    }

    var isSearching: Bool {
        !(searchController.searchBar.text?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ?? true)
    }

    var displayedItems: [SavedSlang] {
        isSearching ? filteredItems : items
    }
}
