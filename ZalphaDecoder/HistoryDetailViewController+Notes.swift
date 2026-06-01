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
            navigationItem.rightBarButtonItem = nil
            return
        }

        emptyNotesLabel?.isHidden = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: AppStrings.History.saveAll,
            style: .plain,
            target: self,
            action: #selector(confirmSaveAllNotes)
        )
        notes.prefix(5).forEach {
            notesStackView?.addArrangedSubview(makeNoteView($0))
        }
    }

    /// Removes previously rendered dynamic note rows.
    func clearNotesStackView() {
        navigationItem.rightBarButtonItem = nil
        notesStackView?.arrangedSubviews.forEach {
            guard $0 !== emptyNotesLabel else { return }
            notesStackView?.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func makeNoteView(_ note: DecodeNote) -> UIView {
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
                value: note.sourceExpression,
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

        if !note.translatedExpression.isEmpty {
            contentStackView.addArrangedSubview(
                makeNoteField(
                    title: AppStrings.History.translatedAs,
                    value: note.translatedExpression,
                    valueColor: AppTheme.labelColor,
                    valueFont: .systemFont(ofSize: 15, weight: .medium)
                )
            )
        }

        contentStackView.addArrangedSubview(makeSaveButtonRow(for: note))
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
        button.configuration = nil
        button.setTitle(AppStrings.History.save, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        AppTheme.applySurfaceStyle(
            to: button,
            backgroundColor: AppTheme.accentColor,
            cornerRadius: 16,
            borderWidth: 0
        )
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
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
        let message = note.sourceExpression.isEmpty ? nil : "\"\(note.sourceExpression)\""
        let alertController = UIAlertController(
            title: AppStrings.History.saveTitle,
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .default) { [weak self] _ in
            let result = SavedSlangStore.shared.save(
                note,
                sourceLanguage: self?.item?.sourceLanguage ?? "Unknown",
                meaningLanguage: self?.item?.targetLanguage ?? note.meaningLanguage
            )
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self?.showToast(result.message)
        })
        present(alertController, animated: true)
    }

    @objc private func confirmSaveAllNotes() {
        guard let item = item, !item.notes.isEmpty else { return }

        let alertController = UIAlertController(
            title: AppStrings.History.saveAllTitle,
            message: nil,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: AppStrings.Common.no, style: .cancel))
        alertController.addAction(UIAlertAction(title: AppStrings.Common.yes, style: .default) { [weak self] _ in
            let results = item.notes.map {
                SavedSlangStore.shared.save(
                    $0,
                    sourceLanguage: item.sourceLanguage,
                    meaningLanguage: item.targetLanguage
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
