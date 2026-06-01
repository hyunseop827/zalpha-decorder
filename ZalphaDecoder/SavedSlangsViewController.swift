//
//  SavedSlangsViewController.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Displays locally saved slang notes.
final class SavedSlangsViewController: UIViewController {
    static let savedSlangDetailSegueIdentifier = "ShowSavedSlangDetail"

    @IBOutlet weak var tableView: UITableView!

    var items: [SavedSlang] = []
    var filteredItems: [SavedSlang] = []
    var selectedItem: SavedSlang?
    let searchController = UISearchController(searchResultsController: nil)
    var deleteAllButton: UIBarButtonItem?
    var toastLabel: ToastLabel?
    var toastHideWorkItem: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = AppStrings.SavedSlang.title
        configureNavigationActions()
        configureTableView()
        configureSearchController()
        registerForThemeChanges()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        reloadSavedSlangs()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == Self.savedSlangDetailSegueIdentifier,
              let detailViewController = segue.destination as? SavedSlangDetailViewController else {
            return
        }

        if let selectedItem = selectedItem {
            detailViewController.configure(with: selectedItem)
        }
        selectedItem = nil
    }

    @IBAction func closeButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func reloadSavedSlangs() {
        items = SavedSlangStore.shared.loadItems()
        applySearchFilter(searchController.searchBar.text)
        tableView.reloadData()
        updateBackgroundView()
        updateDeleteAllSavedSlangsButton()
    }
}
