//
//  ViewController+Styling.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import UIKit

/// Groups runtime UI styling that depends on state, trait changes, or layer configuration.
extension ViewController {

    /// Runs the full runtime styling setup for the storyboard-backed interface.
    func configureInterface() {
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.navigationBar.tintColor = labelColor

        configureDynamicColors()
        configureCards()
        configureLanguageButtons()
        configureStyleButtons()
        configureDecodeButton()
        configureTextContainers()
        configureUtilityButtons()
        configureKeyboardDismissal()
    }

    /// Re-applies dynamic colors and shadows when the system light/dark appearance changes.
    func registerForThemeChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (viewController: ViewController, _) in
            viewController.configureDynamicColors()
            viewController.updateStyleSelection()
            viewController.updateShadowPaths()
        }
    }

    /// Applies colors that depend on the current light or dark mode.
    func configureDynamicColors() {
        view.backgroundColor = pageBackgroundColor
        scrollView.backgroundColor = pageBackgroundColor
        contentView.backgroundColor = pageBackgroundColor

        [mainCardView, inputCardView, outputCardView, notesCardView].forEach {
            $0?.backgroundColor = cardBackgroundColor
            $0?.layer.borderColor = borderColor.cgColor
        }

        inputTextView.backgroundColor = .clear
        outputTextView.backgroundColor = .clear
        inputTextView.textColor = labelColor
        outputTextView.textColor = labelColor

        styleLabel.textColor = labelColor
        [inputLanguageLabel, outputLanguageLabel, characterCountLabel, notesTitleLabel].forEach {
            $0?.textColor = secondaryLabelColor
        }
        notesBodyLabel.textColor = labelColor
        toastLabel?.backgroundColor = toastBackgroundColor
        toastLabel?.textColor = toastTextColor

        [sourceLanguageButton, targetLanguageButton].forEach {
            $0?.setTitleColor(labelColor, for: .normal)
            $0?.tintColor = accentColor
            $0?.backgroundColor = controlBackgroundColor
            $0?.layer.borderColor = borderColor.cgColor
        }

        copyButton.tintColor = labelColor
        notesIconButton.tintColor = accentColor
        navigationController?.navigationBar.tintColor = labelColor
    }

    /// Applies card corner radius, border, and shadow layer styling.
    func configureCards() {
        applyCardStyle(to: mainCardView, cornerRadius: 18, shadowOpacity: isDarkMode ? 0.12 : 0.16, shadowRadius: 9)
        applyCardStyle(to: inputCardView, cornerRadius: 12, shadowOpacity: isDarkMode ? 0.10 : 0.18, shadowRadius: 6)
        applyCardStyle(to: outputCardView, cornerRadius: 12, shadowOpacity: isDarkMode ? 0.10 : 0.18, shadowRadius: 6)
        applyCardStyle(to: notesCardView, cornerRadius: 12, shadowOpacity: isDarkMode ? 0.10 : 0.16, shadowRadius: 6)
    }

    /// Configures the source, swap, and target language buttons.
    func configureLanguageButtons() {
        [sourceLanguageButton, targetLanguageButton].forEach {
            $0?.configuration = nil
            $0?.setImage(UIImage(systemName: "globe"), for: .normal)
            $0?.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
            $0?.showsMenuAsPrimaryAction = true
            $0?.changesSelectionAsPrimaryAction = false
            $0?.titleLabel?.adjustsFontSizeToFitWidth = true
            $0?.titleLabel?.minimumScaleFactor = 0.8
            $0?.contentHorizontalAlignment = .center
            $0?.contentEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
            $0?.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
            $0?.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: -4)
            $0?.layer.cornerRadius = 24
            $0?.layer.borderWidth = 1
            $0?.semanticContentAttribute = .forceLeftToRight
            $0?.clipsToBounds = false
            applySmallShadow(to: $0)
        }

        swapLanguageButton.configuration = nil
        swapLanguageButton.setTitle(nil, for: .normal)
        swapLanguageButton.setImage(UIImage(systemName: "arrow.left.arrow.right"), for: .normal)
        swapLanguageButton.tintColor = accentColor
        swapLanguageButton.backgroundColor = controlBackgroundColor
        swapLanguageButton.layer.cornerRadius = 24
        swapLanguageButton.layer.borderWidth = 1
        swapLanguageButton.layer.borderColor = borderColor.cgColor
        swapLanguageButton.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 19, weight: .medium)
        applySmallShadow(to: swapLanguageButton)
    }

    /// Configures shared typography and layer styling for the style buttons.
    func configureStyleButtons() {
        let buttons: [UIButton] = [
            cleanStyleButton,
            plainStyleButton,
            casualStyleButton,
            genZalphaStyleButton
        ]

        buttons.forEach { button in
            button.configuration = nil
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.titleLabel?.adjustsFontSizeToFitWidth = true
            button.titleLabel?.minimumScaleFactor = 0.8
            button.layer.cornerRadius = 17
            button.layer.borderWidth = 1
            button.clipsToBounds = false
            applySmallShadow(to: button)
        }
    }

    /// Configures the main Decode action button.
    func configureDecodeButton() {
        decodeButton.configuration = nil
        decodeButton.setTitle("Decode", for: .normal)
        decodeButton.setTitleColor(.white, for: .normal)
        decodeButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .semibold)
        decodeButton.backgroundColor = accentColor
        decodeButton.layer.cornerRadius = 22
    }

    /// Normalizes text view padding so the storyboard cards keep consistent spacing.
    func configureTextContainers() {
        [inputTextView, outputTextView].forEach {
            $0?.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
            $0?.textContainer.lineFragmentPadding = 0
        }
    }

    /// Configures icon-only utility buttons such as copy and notes.
    func configureUtilityButtons() {
        copyButton.configuration = nil
        copyButton.setTitle(nil, for: .normal)
        copyButton.setImage(UIImage(systemName: "doc.on.doc"), for: .normal)
        copyButton.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 30, weight: .regular)

        notesIconButton.configuration = nil
        notesIconButton.setTitle(nil, for: .normal)
        notesIconButton.setImage(UIImage(systemName: "lightbulb.max"), for: .normal)
        notesIconButton.imageView?.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .regular)
        notesIconButton.isUserInteractionEnabled = false
    }

    /// Adds a background tap gesture used to dismiss the keyboard.
    func configureKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    /// Updates shadow paths after views have final bounds.
    func updateShadowPaths() {
        [mainCardView, inputCardView, outputCardView, notesCardView, sourceLanguageButton, swapLanguageButton, targetLanguageButton, cleanStyleButton, plainStyleButton, casualStyleButton, genZalphaStyleButton].forEach {
            guard let view = $0 else { return }
            view.layer.shadowPath = UIBezierPath(roundedRect: view.bounds, cornerRadius: view.layer.cornerRadius).cgPath
        }
    }

    /// Applies the common rounded card layer style.
    func applyCardStyle(to view: UIView, cornerRadius: CGFloat, shadowOpacity: Float, shadowRadius: CGFloat) {
        view.layer.cornerRadius = cornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.borderWidth = 1
        view.layer.borderColor = borderColor.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = shadowOpacity
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = shadowRadius
        view.clipsToBounds = false
    }

    /// Applies the common subtle button shadow style.
    func applySmallShadow(to view: UIView?) {
        view?.layer.shadowColor = UIColor.black.cgColor
        view?.layer.shadowOpacity = isDarkMode ? 0.10 : 0.18
        view?.layer.shadowOffset = CGSize(width: 0, height: 2)
        view?.layer.shadowRadius = 3
    }

    var isDarkMode: Bool {
        traitCollection.userInterfaceStyle == .dark
    }

    var pageBackgroundColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1.0)
                : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        }
    }

    var cardBackgroundColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.12, blue: 0.13, alpha: 1.0)
                : UIColor.white
        }
    }

    var controlBackgroundColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.17, green: 0.17, blue: 0.18, alpha: 1.0)
                : UIColor.white
        }
    }

    var borderColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.14)
                : UIColor(white: 0.0, alpha: 0.16)
        }
    }

    var labelColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        }
    }

    var secondaryLabelColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.58)
                : UIColor(white: 0.0, alpha: 0.42)
        }
    }

    var toastBackgroundColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(white: 1.0, alpha: 0.90)
                : UIColor(white: 0.0, alpha: 0.86)
        }
    }

    var toastTextColor: UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
        }
    }
}
