//
//  HistoryViewController.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Displays locally saved decode history records.
final class HistoryViewController: UIViewController {
    static let historyDetailSegueIdentifier = "ShowHistoryDetail"

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var deleteAllHistoryButton: UIBarButtonItem!

    var items: [HistoryItem] = []
    var filteredItems: [HistoryItem] = []
    var selectedItem: HistoryItem?
    let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = AppStrings.History.title
        configureTableView()
        configureSearchController()
        registerForThemeChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadHistory()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == Self.historyDetailSegueIdentifier,
              let detailViewController = segue.destination as? HistoryDetailViewController else {
            return
        }

        if let selectedItem = selectedItem {
            detailViewController.configure(with: selectedItem)
        }
        selectedItem = nil
    }

    func reloadHistory() {
        items = HistoryStore.shared.loadItems()
        applySearchFilter(searchController.searchBar.text)
        tableView.reloadData()
        updateBackgroundView()
        updateDeleteAllButtonState()
    }
}

enum HistoryDateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = AppStrings.dateLocale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
