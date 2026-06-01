//
//  AIService.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import Foundation

/// Coordinates prompt creation, raw AI generation, and response parsing.
final class AIService {
    private let textGenerator: AITextGenerating
    private let promptBuilder: AIServicePromptBuilder
    private let responseParser: AIServiceResponseParser

    init() {
        self.textGenerator = FirebaseAITextClient()
        self.promptBuilder = AIServicePromptBuilder()
        self.responseParser = AIServiceResponseParser()
    }

    init(
        textGenerator: AITextGenerating,
        promptBuilder: AIServicePromptBuilder = AIServicePromptBuilder(),
        responseParser: AIServiceResponseParser = AIServiceResponseParser()
    ) {
        self.textGenerator = textGenerator
        self.promptBuilder = promptBuilder
        self.responseParser = responseParser
    }

    /// Sends the user's text to Gemini and returns the decoded result with optional notes.
    func decode(
        text: String,
        sourceLanguage: String,
        targetLanguage: String,
        noteLanguage: String,
        style: TranslationStyle
    ) async throws -> DecodeResult {
        let prompt = promptBuilder.makeDecodePrompt(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            noteLanguage: noteLanguage,
            style: style
        )
        let rawText = try await textGenerator.generateRawText(prompt: prompt, task: .decode)

        return try responseParser.parseDecodeResult(
            from: rawText,
            sourceText: text,
            noteLanguage: noteLanguage
        )
    }

    /// Generates one short example sentence for one saved slang expression.
    func generateExample(
        expression: String,
        meaning: String,
        sourceLanguage: String,
        meaningLanguage: String,
        existingExamples: [String] = []
    ) async throws -> GeneratedSlangExample {
        let prompt = promptBuilder.makeExamplePrompt(
            expression: expression,
            meaning: meaning,
            sourceLanguage: sourceLanguage,
            meaningLanguage: meaningLanguage,
            existingExamples: existingExamples
        )
        let rawText = try await textGenerator.generateRawText(prompt: prompt, task: .example)

        return try responseParser.parseGeneratedExample(from: rawText)
    }
}
