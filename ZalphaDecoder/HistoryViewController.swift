//
//  HistoryViewController.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Displays locally saved decode history records.
final class HistoryViewController: UIViewController {
    private static let historyDetailSegueIdentifier = "ShowHistoryDetail"

    @IBOutlet weak var tableView: UITableView!

    private var items: [HistoryItem] = []
    private var selectedItem: HistoryItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "History"
        configureTableView()
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

    private func configureTableView() {
        configureDynamicColors()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 154
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 20, right: 0)
        tableView.showsVerticalScrollIndicator = true

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
    }

    private func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: HistoryViewController, _) in
            viewController.configureDynamicColors()
            viewController.tableView.reloadData()
        }
    }

    private func configureDynamicColors() {
        view.backgroundColor = pageBackgroundColor
    }

    private func reloadHistory() {
        items = HistoryStore.shared.loadItems()
        tableView.reloadData()
        updateBackgroundView()
    }

    private func updateBackgroundView() {
        guard items.isEmpty else {
            tableView.backgroundView = nil
            return
        }

        let label = UILabel()
        label.text = "No history yet."
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        tableView.backgroundView = label
    }

    private var pageBackgroundColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
                : UIColor.systemGray6
        }
    }
}

extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: HistoryCell.reuseIdentifier,
            for: indexPath
        ) as? HistoryCell else {
            return UITableViewCell()
        }

        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectedItem = items[indexPath.row]
        performSegue(withIdentifier: Self.historyDetailSegueIdentifier, sender: self)
    }
}

enum HistoryDateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
