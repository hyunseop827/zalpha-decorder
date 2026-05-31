//
//  ViewController.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Main storyboard-backed screen controller for user actions and screen state.
class ViewController: UIViewController, UIGestureRecognizerDelegate {
    private static let currentDecodeDetailSegueIdentifier = "ShowCurrentDecodeDetail"

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var mainCardView: UIView!
    @IBOutlet weak var inputCardView: UIView!
    @IBOutlet weak var outputCardView: UIView!
    @IBOutlet weak var notesCardView: UIView!

    @IBOutlet weak var sourceLanguageButton: UIButton!
    @IBOutlet weak var swapLanguageButton: UIButton!
    @IBOutlet weak var targetLanguageButton: UIButton!

    @IBOutlet weak var cleanStyleButton: UIButton!
    @IBOutlet weak var plainStyleButton: UIButton!
    @IBOutlet weak var casualStyleButton: UIButton!
    @IBOutlet weak var genZalphaStyleButton: UIButton!
    @IBOutlet weak var decodeButton: UIButton!

    @IBOutlet weak var styleLabel: UILabel!
    @IBOutlet weak var inputLanguageLabel: UILabel!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var characterCountLabel: UILabel!
    @IBOutlet weak var outputLanguageLabel: UILabel!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var copyButton: UIButton!
    @IBOutlet weak var notesIconButton: UIButton!
    @IBOutlet weak var notesTitleLabel: UILabel!
    @IBOutlet weak var notesBodyLabel: UILabel!
    @IBOutlet weak var loadingOverlayView: UIView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loadingTitleLabel: UILabel!

    let aiService = AIService()
    let screenModel = DecodeScreenModel()
    private var textInputController: TextInputController?
    var toastLabel: ToastLabel?
    var toastHideWorkItem: DispatchWorkItem?

    /// Performs one-time screen setup after storyboard outlets are connected.
    override func viewDidLoad() {
        super.viewDidLoad()

        configureTextInputController()
        configureInterface()
        registerForThemeChanges()
        updateStyleSelection()
        updateLanguageInterface()
        updateLocalizedInterface()
        updateCharacterCount()
    }

    /// Refreshes shadow paths after Auto Layout has final view sizes.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updateShadowPaths()
    }

    /// Shows the custom startup splash once the screen is visible.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        showStartupSplashIfNeeded()
    }

    /// Passes the latest decoded item into the detail screen when the notes card is tapped.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == Self.currentDecodeDetailSegueIdentifier,
              let detailViewController = segue.destination as? HistoryDetailViewController,
              let latestHistoryItem = screenModel.latestHistoryItem else {
            return
        }

        detailViewController.configure(with: latestHistoryItem)
    }

    /// Updates the selected style when one of the style buttons is tapped.
    @IBAction func styleButtonTapped(_ sender: UIButton) {
        let selectedStyle: TranslationStyle
        switch sender {
        case cleanStyleButton:
            selectedStyle = .formal
        case plainStyleButton:
            selectedStyle = .plain
        case casualStyleButton:
            selectedStyle = .casual
        case genZalphaStyleButton:
            selectedStyle = .genZalpha
        default:
            selectedStyle = .formal
        }

        screenModel.selectStyle(selectedStyle)
        updateStyleSelection()
    }

    /// Starts the Decode flow unless an existing decode request is already running.
    @IBAction func decodeButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        guard !screenModel.isDecoding else { return }

        Task { [weak self] in
            await self?.runDecode()
        }
    }

    /// Swaps source and target language while keeping Auto out of the target menu.
    @IBAction func swapLanguageButtonTapped(_ sender: UIButton) {
        screenModel.swapLanguages()
        updateLanguageInterface()
    }

    /// Copies the current output text to the system clipboard.
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        let output = outputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { return }

        UIPasteboard.general.string = output
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast(AppStrings.Main.outputCopied)
    }

    /// Opens the current decode result in the History Detail screen.
    @objc func notesCardTapped() {
        guard screenModel.latestHistoryItem != nil else {
            showToast(AppStrings.Main.noCurrentDecode)
            return
        }

        performSegue(withIdentifier: Self.currentDecodeDetailSegueIdentifier, sender: self)
    }

    /// Ends text editing when the background tap gesture fires.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Allows background taps to dismiss the keyboard without blocking input text view touches.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        textInputController?.gestureRecognizer(gestureRecognizer, shouldReceive: touch) ?? true
    }

    /// Applies selected and unselected visual states to the style button group.
    func updateStyleSelection() {
        let styles: [(TranslationStyle, UIButton)] = [
            (.formal, cleanStyleButton),
            (.plain, plainStyleButton),
            (.casual, casualStyleButton),
            (.genZalpha, genZalphaStyleButton)
        ]

        styles.forEach { style, button in
            let isSelected = style == screenModel.selectedStyle
            button.backgroundColor = isSelected ? accentColor : controlBackgroundColor
            button.setTitleColor(isSelected ? .white : labelColor, for: .normal)
            button.layer.borderColor = isSelected ? UIColor.clear.cgColor : borderColor.cgColor
            button.accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        }
    }

    /// Refreshes language button titles, menus, and input/output language labels.
    func updateLanguageInterface() {
        configureLanguageButton(sourceLanguageButton, language: screenModel.sourceLanguage)
        configureLanguageButton(targetLanguageButton, language: screenModel.targetLanguage)
        sourceLanguageButton.menu = makeLanguageMenu(
            selectedLanguage: screenModel.sourceLanguage,
            options: DecodeLanguage.sourceOptions,
            changesSource: true
        )
        targetLanguageButton.menu = makeLanguageMenu(
            selectedLanguage: screenModel.targetLanguage,
            options: DecodeLanguage.targetOptions,
            changesSource: false
        )
        inputLanguageLabel.text = AppStrings.Main.inputTitle(screenModel.sourceLanguage.localizedDisplayName)
        outputLanguageLabel.text = AppStrings.Main.outputTitle(screenModel.targetLanguage.localizedDisplayName)
        updateLocalizedInterface()
    }

    /// Applies localized runtime strings that are not purely data-driven.
    func updateLocalizedInterface() {
        navigationItem.title = AppStrings.Main.title
        styleLabel.text = AppStrings.Main.style
        cleanStyleButton.setTitle(TranslationStyle.formal.localizedDisplayName, for: .normal)
        plainStyleButton.setTitle(TranslationStyle.plain.localizedDisplayName, for: .normal)
        casualStyleButton.setTitle(TranslationStyle.casual.localizedDisplayName, for: .normal)
        genZalphaStyleButton.setTitle(TranslationStyle.genZalpha.localizedDisplayName, for: .normal)
        decodeButton.setTitle(AppStrings.Main.decodeButton, for: .normal)
        notesTitleLabel.text = AppStrings.Main.notesTitle
        loadingTitleLabel.text = AppStrings.Decode.loadingTitle
    }

    /// Applies the current language name and shared icon styling to a language button.
    private func configureLanguageButton(_ button: UIButton, language: DecodeLanguage) {
        button.setTitle(language.localizedDisplayName, for: .normal)
        button.setTitleColor(labelColor, for: .normal)
        button.tintColor = accentColor
        button.accessibilityLabel = language.localizedDisplayName
    }

    /// Builds the source or target language menu from the available language options.
    private func makeLanguageMenu(
        selectedLanguage: DecodeLanguage,
        options: [DecodeLanguage],
        changesSource: Bool
    ) -> UIMenu {
        let actions = options.map { language in
            UIAction(
                title: language.localizedDisplayName,
                state: language == selectedLanguage ? .on : .off
            ) { [weak self] _ in
                self?.setLanguage(language, changesSource: changesSource)
            }
        }

        return UIMenu(children: actions)
    }

    /// Stores the selected source or target language and refreshes the visible UI.
    private func setLanguage(_ language: DecodeLanguage, changesSource: Bool) {
        screenModel.setLanguage(language, changesSource: changesSource)
        updateLanguageInterface()
    }

    /// Updates the visible input character counter.
    private func updateCharacterCount() {
        let count = inputTextView.text.count
        characterCountLabel.text = "\(count)/\(TextInputController.maximumInputLength)"
    }

    /// Keeps text input delegate behavior strongly retained outside UIKit weak delegate storage.
    private func configureTextInputController() {
        textInputController = TextInputController(
            inputTextView: inputTextView,
            onTextChanged: { [weak self] in
                self?.updateCharacterCount()
            },
            onNonEmptyInput: { [weak self] in
                self?.screenModel.resetEmptyDecodeTapCount()
            }
        )
    }
}
