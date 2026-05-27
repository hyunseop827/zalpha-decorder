//
//  ViewController.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Output tone options shared by the style buttons and AI prompt.
enum TranslationStyle {
    case formal
    case plain
    case casual
    case genZalpha
}

/// Main storyboard-backed screen controller for user actions and screen state.
class ViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {

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

    /// Supported language options shown in the source and target menus.
    enum Language: CaseIterable {
        case auto
        case english
        case korean

        var displayName: String {
            switch self {
            case .auto:
                return "Auto"
            case .english:
                return "English"
            case .korean:
                return "한국어"
            }
        }

        static let sourceOptions: [Language] = [.auto, .english, .korean]
        static let targetOptions: [Language] = [.english, .korean]
    }

    /// Main accent color used by buttons, symbols, and selected states.
    let accentColor = UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1.0)
    let aiService = AIService()
    var isDecoding = false
    var hasShownStartupSplash = false
    var emptyDecodeTapCount = 0
    private let maximumInputLength = 100
    var toastLabel: ToastLabel?
    var toastHideWorkItem: DispatchWorkItem?
    var selectedStyle: TranslationStyle = .formal
    var sourceLanguage: Language = .auto
    var targetLanguage: Language = .english

    /// Performs one-time screen setup after storyboard outlets are connected.
    override func viewDidLoad() {
        super.viewDidLoad()

        inputTextView.delegate = self
        configureInterface()
        registerForThemeChanges()
        updateStyleSelection()
        updateLanguageInterface()
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

    /// Updates the selected style when one of the style buttons is tapped.
    @IBAction func styleButtonTapped(_ sender: UIButton) {
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

        updateStyleSelection()
    }

    /// Starts the Decode flow unless an existing decode request is already running.
    @IBAction func decodeButtonTapped(_ sender: UIButton) {
        view.endEditing(true)
        guard !isDecoding else { return }

        Task { [weak self] in
            await self?.runDecode()
        }
    }

    /// Swaps source and target language while keeping Auto out of the target menu.
    @IBAction func swapLanguageButtonTapped(_ sender: UIButton) {
        if sourceLanguage == .auto {
            sourceLanguage = targetLanguage
            targetLanguage = oppositeLanguage(of: sourceLanguage)
        } else {
            swap(&sourceLanguage, &targetLanguage)
        }

        updateLanguageInterface()
    }

    /// Copies the current output text to the system clipboard.
    @IBAction func copyButtonTapped(_ sender: UIButton) {
        let output = outputTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !output.isEmpty else { return }

        UIPasteboard.general.string = output
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showToast("Saved to clipboard.")
    }

    /// Ends text editing when the background tap gesture fires.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    /// Keeps input state, empty-input count, and character counter in sync while typing.
    func textViewDidChange(_ textView: UITextView) {
        if textView == inputTextView, textView.text.count > maximumInputLength {
            textView.text = String(textView.text.prefix(maximumInputLength))
        }

        if textView == inputTextView, !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emptyDecodeTapCount = 0
        }

        updateCharacterCount()
    }

    /// Prevents the input text view from accepting more than the maximum allowed characters.
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard textView == inputTextView else { return true }
        guard let currentText = textView.text, let stringRange = Range(range, in: currentText) else {
            return false
        }

        let updatedText = currentText.replacingCharacters(in: stringRange, with: text)
        guard updatedText.count > maximumInputLength else { return true }

        let replacedLength = currentText[stringRange].count
        let remainingCount = maximumInputLength - (currentText.count - replacedLength)
        guard remainingCount > 0 else { return false }

        let allowedText = String(text.prefix(remainingCount))
        textView.text = currentText.replacingCharacters(in: stringRange, with: allowedText)
        updateCharacterCount()
        return false
    }

    /// Allows background taps to dismiss the keyboard without blocking input text view touches.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchedView = touch.view else { return true }
        return !touchedView.isDescendant(of: inputTextView)
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
            let isSelected = style == selectedStyle
            button.backgroundColor = isSelected ? accentColor : controlBackgroundColor
            button.setTitleColor(isSelected ? .white : labelColor, for: .normal)
            button.layer.borderColor = isSelected ? UIColor.clear.cgColor : borderColor.cgColor
            button.accessibilityTraits = isSelected ? [.button, .selected] : [.button]
        }
    }

    /// Refreshes language button titles, menus, and input/output language labels.
    func updateLanguageInterface() {
        configureLanguageButton(sourceLanguageButton, language: sourceLanguage)
        configureLanguageButton(targetLanguageButton, language: targetLanguage)
        sourceLanguageButton.menu = makeLanguageMenu(
            selectedLanguage: sourceLanguage,
            options: Language.sourceOptions,
            changesSource: true
        )
        targetLanguageButton.menu = makeLanguageMenu(
            selectedLanguage: targetLanguage,
            options: Language.targetOptions,
            changesSource: false
        )
        inputLanguageLabel.text = "Input - \(sourceLanguage.displayName)"
        outputLanguageLabel.text = "Output - \(targetLanguage.displayName)"
    }

    /// Applies the current language name and shared icon styling to a language button.
    private func configureLanguageButton(_ button: UIButton, language: Language) {
        button.setTitle(language.displayName, for: .normal)
        button.setTitleColor(labelColor, for: .normal)
        button.tintColor = accentColor
        button.accessibilityLabel = language.displayName
    }

    /// Builds the source or target language menu from the available language options.
    private func makeLanguageMenu(selectedLanguage: Language, options: [Language], changesSource: Bool) -> UIMenu {
        let actions = options.map { language in
            UIAction(
                title: language.displayName,
                state: language == selectedLanguage ? .on : .off
            ) { [weak self] _ in
                self?.setLanguage(language, changesSource: changesSource)
            }
        }

        return UIMenu(children: actions)
    }

    /// Stores the selected source or target language and refreshes the visible UI.
    private func setLanguage(_ language: Language, changesSource: Bool) {
        if changesSource {
            sourceLanguage = language
        } else {
            targetLanguage = language
        }

        updateLanguageInterface()
    }

    /// Returns the opposite concrete language used when swapping from Auto mode.
    private func oppositeLanguage(of language: Language) -> Language {
        language == .english ? .korean : .english
    }

    /// Updates the visible input character counter.
    private func updateCharacterCount() {
        let count = inputTextView.text.count
        characterCountLabel.text = "\(count)/\(maximumInputLength)"
    }
}
