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
    @IBOutlet weak var notesTitleLabel: UILabel?
    @IBOutlet weak var saveAllNotesButton: UIButton?
    @IBOutlet weak var notesStackView: UIStackView?
    @IBOutlet weak var emptyNotesLabel: UILabel?

    var item: HistoryItem?
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

        navigationItem.title = AppStrings.History.detailTitle
        configureStoryboardViews()
        registerForThemeChanges()
        renderItem()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateShadowPaths()
    }

    func renderItem() {
        configureSaveAllNotesButton()
        clearNotesStackView()

        guard let item = item else {
            metadataLabel?.text = ""
            inputTitleLabel?.text = AppStrings.History.input
            inputBodyLabel?.text = ""
            outputTitleLabel?.text = AppStrings.History.output
            outputBodyLabel?.text = ""
            emptyNotesLabel?.text = AppStrings.History.noItemSelected
            emptyNotesLabel?.isHidden = false
            return
        }

        let sourceLanguage = DecodeLanguage.localizedDisplayName(for: item.sourceLanguage)
        let targetLanguage = DecodeLanguage.localizedDisplayName(for: item.targetLanguage)

        metadataLabel?.text = "\(HistoryDateFormatter.shortDateTime.string(from: item.createdAt)) · \(TranslationStyle.localizedDisplayName(for: item.style))"
        inputTitleLabel?.text = AppStrings.History.inputTitle(sourceLanguage)
        inputBodyLabel?.text = item.inputText
        outputTitleLabel?.text = AppStrings.History.outputTitle(targetLanguage)
        outputBodyLabel?.text = item.outputText
        notesTitleLabel?.text = AppStrings.Main.notesTitle
        renderNotes(item.notes)
    }
}
