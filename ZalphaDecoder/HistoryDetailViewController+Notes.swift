//
//  HistoryDetailViewController+Notes.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Builds and handles the structured Decode Notes shown in history detail.
extension HistoryDetailViewController {

    /// Renders up to three saved notes into the notes stack.
    func renderNotes(_ notes: [DecodeNote]) {
        guard !notes.isEmpty else {
            emptyNotesLabel?.text = "No notes for this decode."
            emptyNotesLabel?.isHidden = false
            return
        }

        emptyNotesLabel?.isHidden = true
        notes.prefix(3).forEach {
            notesStackView?.addArrangedSubview(makeNoteView($0))
        }
    }

    /// Removes previously rendered dynamic note rows.
    func clearNotesStackView() {
        notesStackView?.arrangedSubviews.forEach {
            guard $0 !== emptyNotesLabel else { return }
            notesStackView?.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func makeNoteView(_ note: DecodeNote) -> UIView {
        let view = UIView()
        view.backgroundColor = noteCardBackgroundColor
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = noteBorderColor.cgColor

        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 9
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(
            makeNoteField(
                title: "Expression",
                value: note.sourceExpression,
                valueColor: accentColor,
                valueFont: .systemFont(ofSize: 16, weight: .semibold)
            )
        )
        contentStackView.addArrangedSubview(
            makeNoteField(
                title: "Meaning",
                value: note.meaning,
                valueColor: .label,
                valueFont: .systemFont(ofSize: 15, weight: .medium)
            )
        )

        if !note.translatedExpression.isEmpty {
            contentStackView.addArrangedSubview(
                makeNoteField(
                    title: "Translated As",
                    value: note.translatedExpression,
                    valueColor: .label,
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
        button.setTitle("Save", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = accentColor
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
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
            title: "Save this note?",
            message: message,
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "No", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self?.showToast("Note saved.")
        })
        present(alertController, animated: true)
    }

    private var noteCardBackgroundColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.16, green: 0.16, blue: 0.18, alpha: 1)
                : UIColor.systemGray6
        }
    }

    private var noteBorderColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.10)
                : UIColor(white: 0, alpha: 0.08)
        }
    }
}
