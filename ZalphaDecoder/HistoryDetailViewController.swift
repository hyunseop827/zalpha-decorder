//
//  HistoryDetailViewController.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Storyboard-backed read-only detail view for one saved decode history item.
final class HistoryDetailViewController: UIViewController {
    @IBOutlet weak var inputCardView: UIView?
    @IBOutlet weak var outputCardView: UIView?
    @IBOutlet weak var notesCardView: UIView?
    @IBOutlet weak var metadataLabel: UILabel?
    @IBOutlet weak var inputTitleLabel: UILabel?
    @IBOutlet weak var inputBodyLabel: UILabel?
    @IBOutlet weak var outputTitleLabel: UILabel?
    @IBOutlet weak var outputBodyLabel: UILabel?
    @IBOutlet weak var notesStackView: UIStackView?
    @IBOutlet weak var emptyNotesLabel: UILabel?
    @IBOutlet weak var saveNotesButton: UIButton?

    private var item: HistoryItem?
    private let accentColor = UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1.0)
    private var toastLabel: ToastLabel?
    private var toastHideWorkItem: DispatchWorkItem?

    /// Receives the selected history item before the storyboard detail screen is shown.
    func configure(with item: HistoryItem) {
        self.item = item

        if isViewLoaded {
            renderItem()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "History Detail"
        configureStoryboardViews()
        renderItem()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateShadowPaths()
    }

    private func configureStoryboardViews() {
        view.backgroundColor = pageBackgroundColor
        metadataLabel?.numberOfLines = 0
        metadataLabel?.textColor = secondaryLabelColor
        inputTitleLabel?.textColor = .secondaryLabel
        outputTitleLabel?.textColor = .secondaryLabel
        inputBodyLabel?.numberOfLines = 0
        outputBodyLabel?.numberOfLines = 0
        emptyNotesLabel?.numberOfLines = 0
        emptyNotesLabel?.textColor = .secondaryLabel
        notesStackView?.axis = .vertical
        notesStackView?.spacing = 10
        configureCards()
        configureSaveNotesButton()
    }

    private func configureCards() {
        [inputCardView, outputCardView, notesCardView].forEach {
            applyCardStyle(to: $0)
        }
    }

    private func configureSaveNotesButton() {
        saveNotesButton?.configuration = nil
        saveNotesButton?.setTitle("Save Notes", for: .normal)
        saveNotesButton?.setTitleColor(.white, for: .normal)
        saveNotesButton?.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        saveNotesButton?.backgroundColor = accentColor
        saveNotesButton?.layer.cornerRadius = 22
        saveNotesButton?.layer.cornerCurve = .continuous
        saveNotesButton?.clipsToBounds = true
    }

    private func applyCardStyle(to view: UIView?) {
        guard let view else { return }

        view.backgroundColor = cardBackgroundColor
        view.layer.cornerRadius = 14
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = borderColor.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = isDarkMode ? 0.08 : 0.14
        view.layer.shadowRadius = 6
        view.layer.shadowOffset = CGSize(width: 0, height: 3)
    }

    private func updateShadowPaths() {
        [inputCardView, outputCardView, notesCardView].forEach { view in
            guard let view else { return }
            view.layer.shadowPath = UIBezierPath(
                roundedRect: view.bounds,
                cornerRadius: view.layer.cornerRadius
            ).cgPath
        }
    }

    private func renderItem() {
        clearNotesStackView()

        guard let item = item else {
            metadataLabel?.text = ""
            inputTitleLabel?.text = "Input"
            inputBodyLabel?.text = ""
            outputTitleLabel?.text = "Output"
            outputBodyLabel?.text = ""
            emptyNotesLabel?.text = "No history item selected."
            emptyNotesLabel?.isHidden = false
            return
        }

        metadataLabel?.text = "\(HistoryDateFormatter.shortDateTime.string(from: item.createdAt)) · \(item.style)"
        inputTitleLabel?.text = "Input - \(item.sourceLanguage)"
        inputBodyLabel?.text = item.inputText
        outputTitleLabel?.text = "Output - \(item.targetLanguage)"
        outputBodyLabel?.text = item.outputText
        renderNotes(item.notes)
    }

    @IBAction func saveNotesButtonTapped(_ sender: UIButton) {
        guard item?.notes.isEmpty == false else {
            showToast("No notes to save.")
            return
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Notes saved.")
    }

    private func renderNotes(_ notes: [DecodeNote]) {
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

    private func clearNotesStackView() {
        notesStackView?.arrangedSubviews.forEach {
            guard $0 !== emptyNotesLabel else { return }
            notesStackView?.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }

    private func makeNoteView(_ note: DecodeNote) -> UIView {
        let label = UILabel()
        label.text = formattedNoteText(for: note)
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0

        let view = UIView()
        view.backgroundColor = .tertiarySystemGroupedBackground
        view.layer.cornerRadius = 10
        view.layer.cornerCurve = .continuous
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])

        return view
    }

    private var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }

    private var pageBackgroundColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
                : UIColor.systemGray6
        }
    }

    private var cardBackgroundColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1)
                : UIColor.white
        }
    }

    private var borderColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.14)
                : UIColor(white: 0, alpha: 0.12)
        }
    }

    private var secondaryLabelColor: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.62)
                : UIColor(white: 0, alpha: 0.52)
        }
    }

    private func formattedNoteText(for note: DecodeNote) -> String {
        let translatedText = note.translatedExpression.isEmpty
            ? ""
            : "\nTranslated as: \(note.translatedExpression)"
        return "\(note.sourceExpression)\nMeaning: \(note.meaning)\(translatedText)"
    }

    private func showToast(_ message: String) {
        toastHideWorkItem?.cancel()

        let label = toastLabel ?? makeToastLabel()
        label.text = message
        label.alpha = 0
        label.transform = CGAffineTransform(translationX: 0, y: 8)
        view.bringSubviewToFront(label)

        UIView.animate(withDuration: 0.2) {
            label.alpha = 1
            label.transform = .identity
        }

        let workItem = DispatchWorkItem { [weak label] in
            UIView.animate(withDuration: 0.2) {
                label?.alpha = 0
                label?.transform = CGAffineTransform(translationX: 0, y: 8)
            }
        }
        toastHideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: workItem)
    }

    private func makeToastLabel() -> ToastLabel {
        let label = ToastLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(white: 1, alpha: 0.92)
                : UIColor(white: 0.05, alpha: 0.92)
        }
        label.textColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? .black : .white
        }
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textAlignment = .center
        label.layer.cornerRadius = 12
        label.layer.cornerCurve = .continuous
        label.clipsToBounds = true

        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 40)
        ])

        toastLabel = label
        return label
    }
}
