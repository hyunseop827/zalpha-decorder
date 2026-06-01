//
//  SavedSlangDetailViewController.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Storyboard-backed read-only detail view for one saved slang item.
final class SavedSlangDetailViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var expressionLabel: UILabel!
    @IBOutlet weak var expressionCopyButton: UIButton!
    @IBOutlet weak var metadataLabel: UILabel!
    @IBOutlet weak var meaningsCardView: UIView!
    @IBOutlet weak var meaningsTitleLabel: UILabel?
    @IBOutlet weak var meaningsStackView: UIStackView!
    @IBOutlet weak var translationsCardView: UIView!
    @IBOutlet weak var originalExpressionsTitleLabel: UILabel?
    @IBOutlet weak var translationsStackView: UIStackView!
    @IBOutlet weak var examplesCardView: UIView!
    @IBOutlet weak var examplesTitleLabel: UILabel?
    @IBOutlet weak var examplesStackView: UIStackView!
    @IBOutlet weak var generateExamplesButton: UIButton!
    @IBOutlet weak var examplesLoadingOverlayView: UIView!
    @IBOutlet weak var examplesLoadingCardView: UIView!
    @IBOutlet weak var examplesLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var examplesLoadingLabel: UILabel!

    let aiService = AIService()
    var item: SavedSlang?
    var isGeneratingExamples = false
    var exampleCopyTexts: [String] = []
    var exampleIDs: [UUID] = []
    var toastLabel: ToastLabel?
    var toastHideWorkItem: DispatchWorkItem?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = AppStrings.SavedSlang.detailTitle
        configureDynamicColors()
        configureCards()
        registerForThemeChanges()
        renderItem()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateShadowPaths()
    }

    /// Sets the saved slang item that should be rendered by this detail view.
    func configure(with item: SavedSlang) {
        self.item = item

        if isViewLoaded {
            renderItem()
        }
    }

    func renderItem() {
        meaningsTitleLabel?.text = AppStrings.SavedSlang.meaningsTitle
        originalExpressionsTitleLabel?.text = AppStrings.SavedSlang.originalExpressionsTitle
        examplesTitleLabel?.text = AppStrings.SavedSlang.examplesTitle
        generateExamplesButton.setTitle(AppStrings.SavedSlang.generateExample, for: .normal)

        guard let item else { return }

        expressionLabel.text = item.expression
        metadataLabel.text = AppStrings.SavedSlang.metadata(
            expressionLanguage: item.expressionLanguage,
            meaningLanguage: item.meaningLanguage,
            date: HistoryDateFormatter.shortDateTime.string(from: item.updatedAt)
        )
        renderValues(item.meanings, in: meaningsStackView, emptyText: AppStrings.SavedSlang.noMeanings)
        renderValues(item.originalExpressions, in: translationsStackView, emptyText: AppStrings.SavedSlang.noOriginalExpressions)
        renderExamples(item.examples)
    }
}
