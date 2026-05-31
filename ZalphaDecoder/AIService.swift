//
//  AIService.swift
//  ZalphaDecoder
//
//  Created by 김현섭 on 5/6/26.
//

import FirebaseAILogic
import Foundation

/// Normalized AI errors that the UI can map to user-facing messages.
enum AIServiceError: Error {
    case emptyResponse
    case blocked
    case rateLimited
    case networkUnavailable
    case serviceUnavailable
    case configuration
    case invalidResponse
}

/// Structured Decode Note that can later become a vocabulary item.
struct DecodeNote: Codable {
    let sourceExpression: String
    let meaning: String
    let translatedExpression: String
}

/// Parsed Gemini response containing the final decoded output and optional notes.
struct DecodeResult: Decodable {
    let result: String
    let notes: [DecodeNote]
}

/// Thin Firebase AI Logic wrapper that builds decode prompts and returns cleaned model text.
final class AIService {
    private lazy var model = FirebaseAI.firebaseAI(backend: .googleAI()).generativeModel(
        modelName: "gemini-3.1-flash-lite",
        safetySettings: [
            SafetySetting(harmCategory: .harassment, threshold: .blockOnlyHigh)
        ]
    )

    /// Sends the user's text to Gemini and returns the decoded result with optional notes.
    func decode(text: String, sourceLanguage: String, targetLanguage: String, style: TranslationStyle) async throws -> DecodeResult {
        let prompt = makePrompt(
            text: text,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            style: style
        )
        let response: GenerateContentResponse
        do {
            response = try await model.generateContent(prompt)
        } catch GenerateContentError.promptBlocked {
            throw AIServiceError.blocked
        } catch GenerateContentError.responseStoppedEarly {
            throw AIServiceError.blocked
        } catch GenerateContentError.internalError(let underlying) {
            throw classifyInternalError(underlying)
        } catch let error as URLError {
            print("Firebase AI Logic network error:", error)
            throw AIServiceError.networkUnavailable
        } catch {
            if let mappedError = mapUnderlyingError(error) {
                throw mappedError
            }

            throw error
        }

        let rawText = response.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !rawText.isEmpty else {
            throw AIServiceError.emptyResponse
        }

        guard let jsonText = extractJSONObject(from: rawText),
              let data = jsonText.data(using: .utf8) else {
            print("Firebase AI Logic invalid JSON response:", rawText)
            throw AIServiceError.invalidResponse
        }

        do {
            let decodedResult = try JSONDecoder().decode(DecodeResult.self, from: data)
            let trimmedResult = decodedResult.result.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedResult.isEmpty else {
                throw AIServiceError.emptyResponse
            }

            return DecodeResult(
                result: trimmedResult,
                notes: decodedResult.notes
                    .map { note in
                        DecodeNote(
                            sourceExpression: note.sourceExpression.trimmingCharacters(in: .whitespacesAndNewlines),
                            meaning: note.meaning.trimmingCharacters(in: .whitespacesAndNewlines),
                            translatedExpression: note.translatedExpression.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    }
                    .filter { !$0.sourceExpression.isEmpty && !$0.meaning.isEmpty }
                    .prefix(3)
                    .map { $0 }
            )
        } catch let error as AIServiceError {
            throw error
        } catch {
            print("Firebase AI Logic invalid JSON response:", rawText)
            throw AIServiceError.invalidResponse
        }
    }

    private func makePrompt(text: String, sourceLanguage: String, targetLanguage: String, style: TranslationStyle) -> String {
        let taskInstruction = sourceLanguage == targetLanguage
            ? "Rewrite or decode the following text in \(targetLanguage) using the selected style."
            : "Translate or decode the following text from \(sourceLanguage) to \(targetLanguage)."

        return """
        \(taskInstruction)
        Preserve the original meaning and emotional intent.
        Keep the result concise, direct, and close in length to the original when possible.
        Do not add hedging, backstory, therapy-like advice, or emotional explanation that is not in the input.
        Short distressed inputs should stay short. For example, "인생 망했다" should become a short result like "My life is ruined.", not a long explanation.
        If the original text contains profanity or harsh wording, preserve the emotional intent but reduce the intensity.
        Do not reproduce strong profanity directly.
        Do not add stronger profanity, hate slurs, threats, sexualized insults, or targeted abuse.
        If the original wording is too intense, soften it into style-appropriate wording instead of refusing.
        \(style.promptInstruction)

        Return only a valid JSON object. Do not use markdown. Do not wrap the JSON in code fences.
        The JSON object must have this shape:
        {
          "result": "final decoded translation",
          "notes": [
            {
              "sourceExpression": "source slang or expression",
              "meaning": "short meaning",
              "translatedExpression": "translated expression used in result"
            }
          ]
        }
        The result must contain only the final decoded translation.
        Notes must be written in English, focus on specific source expressions, and contain at most 3 items.
        Notes should explain only slang, idioms, profanity, meme expressions, abbreviations, or culturally loaded phrases.
        Do not explain ordinary literal words such as nouns, names, pronouns, or basic verbs.
        If a phrase mixes literal words and slang, choose the smallest meaningful slang or idiomatic expression.
        Never use a whole sentence as sourceExpression unless the entire sentence is idiomatic.
        For example, in "인생 조졌다", explain only "조졌다", not "인생" or "인생 조졌다".
        For example, in "야 나 진짜 인생 망했다 ㄹㅇ", explain "망했다" and "ㄹㅇ", not "인생".
        For Korean emotional slang, isolate the slang verb or marker: "조졌다", "망했다", "ㄹㅇ", "개", "찐" when relevant.
        Keep sourceExpression as the smallest source phrase worth saving.
        Keep meaning and translatedExpression short.
        Do not write broad notes like "translated a colloquial expression" or "reframed emotional intensity".
        If no notes are needed, return an empty notes array.

        Text:
        \(text)
        """
    }

    private func extractJSONObject(from text: String) -> String? {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let startIndex = trimmedText.firstIndex(of: "{") else {
            return nil
        }

        var depth = 0
        var isInString = false
        var isEscaped = false
        var index = startIndex

        while index < trimmedText.endIndex {
            let character = trimmedText[index]

            if isEscaped {
                isEscaped = false
            } else if character == "\\" {
                isEscaped = isInString
            } else if character == "\"" {
                isInString.toggle()
            } else if !isInString {
                if character == "{" {
                    depth += 1
                } else if character == "}" {
                    depth -= 1
                    if depth == 0 {
                        return String(trimmedText[startIndex...index])
                    }
                }
            }

            index = trimmedText.index(after: index)
        }

        return nil
    }

    private func classifyInternalError(_ error: Error) -> AIServiceError {
        mapUnderlyingError(error) ?? .serviceUnavailable
    }

    private func mapUnderlyingError(_ error: Error) -> AIServiceError? {
        let nsError = error as NSError
        let description = "\(error) \(nsError.localizedDescription)".lowercased()

        if nsError.code == 429
            || description.contains("429")
            || description.contains("quota exceeded")
            || description.contains("resource_exhausted")
            || description.contains("resourceexhausted")
            || description.contains("rate limit")
            || description.contains("too many requests") {
            return .rateLimited
        }

        if nsError.code == URLError.notConnectedToInternet.rawValue
            || nsError.code == URLError.networkConnectionLost.rawValue
            || nsError.code == URLError.timedOut.rawValue
            || description.contains("not connected")
            || description.contains("offline")
            || description.contains("network")
            || description.contains("timed out")
            || description.contains("timeout")
            || description.contains("urlerror")
            || description.contains("dns")
            || description.contains("cannot connect")
            || description.contains("connection lost") {
            return .networkUnavailable
        }

        if description.contains("403")
            || description.contains("404")
            || description.contains("service_disabled")
            || description.contains("gen_ai_config_not_found")
            || description.contains("api key")
            || description.contains("permission_denied")
            || description.contains("permissiondenied")
            || description.contains("not_found")
            || description.contains("notfound")
            || description.contains("missing a configured gemini")
            || description.contains("has not been used in project") {
            return .configuration
        }

        if description.contains("500")
            || description.contains("502")
            || description.contains("503")
            || description.contains("504")
            || description.contains("unavailable")
            || description.contains("deadline_exceeded")
            || description.contains("deadlineexceeded")
            || description.contains("temporarily unavailable") {
            return .serviceUnavailable
        }

        return nil
    }
}

/// Prompt instructions for each user-visible style option.
private extension TranslationStyle {
    var promptInstruction: String {
        switch self {
        case .formal:
            return """
            Style: Formal.
            Use polished, respectful wording suitable for email, school, or workplace.
            Remove profanity and turn harsh wording into calm, professional language.
            Keep it direct and concise. Do not make it poetic, dramatic, or overly indirect.
            Prefer clear wording like "I made a serious mistake." over vague wording like "my life has taken a difficult turn."
            Example tone: "My life feels ruined."
            """
        case .plain:
            return """
            Style: Plain.
            Use the most normal, natural, easy-to-understand wording.
            Avoid slang, jokes, profanity, formality, and extra flavor.
            Keep it close to how an ordinary person would say it in everyday language.
            Example tone: "My life is ruined."
            """
        case .casual:
            return """
            Style: Casual.
            Use natural friend-to-friend wording. Be relaxed, conversational, and clear.
            Use contractions in English when natural, but do not overdo slang.
            If the input has strong profanity, soften it into mild casual phrases like "messed up", "screwed up", or "this sucks".
            Keep the result short if the input is short.
            Example tone: "I'm so screwed."
            """
        case .genZalpha:
            return """
            Style: Zalpha.
            Use Gen Z / Gen Alpha / brainrot / meme-like wording.
            Slang, exaggeration, and playful dramatic wording are allowed, but preserve the meaning and do not explain the slang in the result.
            Do not make every result random; choose slang that naturally matches the input emotion.
            If the input has strong profanity, soften it into meme-style phrases like "cooked", "not it", "ain't it", or "I'm done".
            Emoji can be used, but use at most one.
            Example tone: "Bro, I'm cooked. 🥀"
            """
        }
    }
}
