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

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var items: [HistoryItem] = []
    private var selectedItem: HistoryItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "History"
        configureTableView()
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
        view.backgroundColor = .systemBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(HistoryCell.self, forCellReuseIdentifier: HistoryCell.reuseIdentifier)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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

private final class HistoryCell: UITableViewCell {
    static let reuseIdentifier = "HistoryCell"

    private let dateLabel = UILabel()
    private let inputLabel = UILabel()
    private let outputLabel = UILabel()
    private let textStackView = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        configureViews()
    }

    func configure(with item: HistoryItem) {
        dateLabel.text = HistoryDateFormatter.shortDateTime.string(from: item.createdAt)
        inputLabel.text = "Input - \(item.sourceLanguage) \"\(item.inputText)\""
        outputLabel.text = "Output - \(item.targetLanguage) \"\(item.outputText)\""
    }

    private func configureViews() {
        accessoryType = .disclosureIndicator

        dateLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        dateLabel.textColor = .secondaryLabel

        [inputLabel, outputLabel].forEach {
            $0.font = .systemFont(ofSize: 15, weight: .medium)
            $0.textColor = .label
            $0.numberOfLines = 2
        }

        textStackView.axis = .vertical
        textStackView.spacing = 6
        textStackView.translatesAutoresizingMaskIntoConstraints = false
        textStackView.addArrangedSubview(dateLabel)
        textStackView.addArrangedSubview(inputLabel)
        textStackView.addArrangedSubview(outputLabel)
        contentView.addSubview(textStackView)

        NSLayoutConstraint.activate([
            textStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            textStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            textStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
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
