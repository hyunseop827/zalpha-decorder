//
//  HistoryDetailViewController+Notes.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Builds and handles the structured Decode Notes shown in history detail.
extension HistoryDetailViewController {

    /// Renders up to five saved notes into the notes stack.
    func renderNotes(_ notes: [DecodeNote]) {
        guard !notes.isEmpty else {
            emptyNotesLabel?.text = AppStrings.History.noNotes
            emptyNotesLabel?.isHidden = false
            updateNavigationActions(hasNotes: false)
            return
        }

        emptyNotesLabel?.isHidden = true
        updateNavigationActions(hasNotes: true)
        notes.prefix(5).forEach {
            notesStackView?.addArrangedSubview(makeNoteView($0))
        }
    }

    /// Removes previously rendered dynamic note rows.
    func clearNotesStackView() {
        saveAllNotesButton?.isHidden = true
        saveAllNotesButton?.isEnabled = false
        notesStackView?.arrangedSubviews.forEach {
            guard $0 !== emptyNotesLabel else { return }
            notesStackView?.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func makeNoteView(_ note: DecodeNote) -> UIView {
        let translatedExpression = note.translatedExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceExpression = note.sourceExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        let view = UIView()
        AppTheme.applySurfaceStyle(
            to: view,
            backgroundColor: AppTheme.noteCardBackgroundColor,
            borderColor: AppTheme.noteBorderColor,
            cornerRadius: 12
        )

        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 9
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(
            makeNoteField(
                title: AppStrings.History.expression,
                value: translatedExpression,
                valueColor: AppTheme.accentColor,
                valueFont: .systemFont(ofSize: 16, weight: .semibold)
            )
        )
        contentStackView.addArrangedSubview(
            makeNoteField(
                title: AppStrings.History.meaning,
                value: note.meaning,
                valueColor: AppTheme.labelColor,
                valueFont: .systemFont(ofSize: 15, weight: .medium)
            )
        )

        contentStackView.addArrangedSubview(
            makeNoteField(
                title: AppStrings.History.originalExpression,
                value: sourceExpression,
                valueColor: AppTheme.labelColor,
                valueFont: .systemFont(ofSize: 15, weight: .medium)
            )
        )

        if !translatedExpression.isEmpty {
            contentStackView.addArrangedSubview(makeSaveButtonRow(for: note))
        }

        view.addSubview(contentStackView)

        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            contentStackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            contentStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])

        return view
    }

    private func makeNoteField(title: String, value: String, valueColor: UIColor, valueFont: UIFont) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = secondaryLabelColor
        titleLabel.numberOfLines = 1

        let valueLabel = UILabel()
        valueLabel.text = value.isEmpty ? "—" : value
        valueLabel.font = valueFont
        valueLabel.textColor = valueColor
        valueLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .vertical
        stackView.spacing = 3
        return stackView
    }

    private func makeSaveButtonRow(for note: DecodeNote) -> UIView {
        let spacerView = UIView()
        let button = UIButton(type: .system)
        var attributedTitle = AttributedString(AppStrings.History.save)
        attributedTitle.font = .systemFont(ofSize: 14, weight: .semibold)

        var configuration = UIButton.Configuration.filled()
        configuration.attributedTitle = attributedTitle
        configuration.baseBackgroundColor = AppTheme.accentColor
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .capsule
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        button.configuration = configuration
        button.addAction(UIAction { [weak self] _ in
            self?.confirmSave(note)
        }, for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [spacerView, button])
        stackView.axis = .horizontal
        stackView.alignment = .center

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 32),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 70)
        ])

        return stackView
    }

    private func confirmSave(_ note: DecodeNote) {
        let expression = note.translatedExpression.trimmingCharacters(in: .whitespacesAndNewlines)
        let message = expression.isEmpty ? nil : "\"\(expression)\""
        let alertController = UIAlertController(
            title: AppStrings.History.saveTitle,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .default) { [weak self] _ in
            let result = SavedSlangStore.shared.save(
                note,
                targetLanguage: self?.item?.targetLanguage ?? "Unknown",
                meaningLanguage: note.meaningLanguage
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self?.showToast(result.message)
        })
        present(alertController, animated: true)
    }

    private func updateNavigationActions(hasNotes: Bool) {
        guard item != nil else {
            navigationItem.rightBarButtonItems = nil
            saveAllNotesButton?.isHidden = true
            saveAllNotesButton?.isEnabled = false
            return
        }

        navigationItem.rightBarButtonItems = [makeDeleteHistoryBarButton()]
        let hasSavableNotes = item?.notes.contains { !$0.translatedExpression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
        saveAllNotesButton?.isHidden = !hasNotes || !hasSavableNotes
        saveAllNotesButton?.isEnabled = hasNotes && hasSavableNotes
    }

    private func makeDeleteHistoryBarButton() -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(confirmDeleteHistory)
        )
        button.tintColor = .systemRed
        return button
    }

    @objc private func confirmDeleteHistory() {
        guard let item = item else { return }

        let alertController = UIAlertController(
            title: AppStrings.History.deleteOneTitle,
            message: AppStrings.History.deleteMessage,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .destructive) { [weak self] _ in
            HistoryStore.shared.delete(id: item.id)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self?.navigationController?.popViewController(animated: true)
        })
        present(alertController, animated: true)
    }

    @IBAction func confirmSaveAllNotes(_ sender: Any) {
        guard let item = item else { return }
        let savableNotes = item.notes.filter {
            !$0.translatedExpression.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !savableNotes.isEmpty else { return }

        let alertController = UIAlertController(
            title: AppStrings.History.saveAllTitle,
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .default) { [weak self] _ in
            let results = savableNotes.map {
                SavedSlangStore.shared.save(
                    $0,
                    targetLanguage: item.targetLanguage,
                    meaningLanguage: $0.meaningLanguage
                )
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self?.showToast(Self.saveAllMessage(for: results))
        })
        present(alertController, animated: true)
    }

    private static func saveAllMessage(for results: [SavedSlangSaveResult]) -> String {
        let savedCount = results.filter { $0 == .saved }.count
        let updatedCount = results.filter { $0 == .updated }.count

        if savedCount > 0, updatedCount > 0 {
            return AppStrings.History.savedAndUpdatedNotes(
                savedCount: savedCount,
                updatedCount: updatedCount
            )
        }

        if savedCount > 0 {
            return AppStrings.History.savedNotes(savedCount)
        }

        if updatedCount > 0 {
            return AppStrings.History.updatedNotes(updatedCount)
        }

        return results.first?.message ?? AppStrings.SavedSlang.invalid
    }
}
