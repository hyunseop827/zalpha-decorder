//
//  HistoryDetailViewController.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Storyboard-backed read-only detail view for one saved decode history item.
final class HistoryDetailViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView?
    @IBOutlet weak var contentView: UIView?
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

    private var item: HistoryItem?
    let accentColor = UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1.0)
    var toastLabel: ToastLabel?
    var toastHideWorkItem: DispatchWorkItem?

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
        registerForThemeChanges()
        renderItem()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateShadowPaths()
    }

    func renderItem() {
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
}
