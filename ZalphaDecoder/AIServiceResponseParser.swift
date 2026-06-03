//
//  AIServiceResponseParser.swift
//  ZalphaDecoder
//

import Foundation

struct AIServiceResponseParser {
    func parseDecodeResult(from rawText: String, sourceText: String, noteLanguage: String) throws -> DecodeResult {
        guard let jsonText = extractJSONObject(from: rawText),
              let data = jsonText.data(using: .utf8) else {
            print("Firebase AI Logic invalid JSON response:", rawText)
            throw AIServiceError.invalidResponse
        }

        do {
            let decodedResult = try JSONDecoder().decode(RawDecodeResult.self, from: data)
            let trimmedResult = decodedResult.result.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !trimmedResult.isEmpty else {
                throw AIServiceError.emptyResponse
            }

            return DecodeResult(
                result: trimmedResult,
                notes: validatedNotes(
                    decodedResult.notes
                    .map { note in
                        let rawMeaningLanguage = note.meaningLanguage?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        let resolvedMeaningLanguage = rawMeaningLanguage.flatMap {
                            $0.isEmpty ? nil : $0
                        } ?? noteLanguage
                        return DecodeNote(
                            expression: note.translatedExpression.trimmingCharacters(in: .whitespacesAndNewlines),
                            meaning: note.meaning.trimmingCharacters(in: .whitespacesAndNewlines),
                            meaningLanguage: resolvedMeaningLanguage,
                            originalExpression: note.sourceExpression.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    }
                    .filter {
                        !$0.originalExpression.isEmpty
                            && !$0.meaning.isEmpty
                            && !$0.expression.isEmpty
                    },
                    sourceText: sourceText
                )
                .prefix(5)
                .map { $0 }
            )
        } catch let error as AIServiceError {
            throw error
        } catch {
            print("Firebase AI Logic invalid JSON response:", rawText)
            throw AIServiceError.invalidResponse
        }
    }

    func parseGeneratedExample(from rawText: String) throws -> GeneratedSlangExample {
        guard let jsonText = extractJSONObject(from: rawText),
              let data = jsonText.data(using: .utf8) else {
            print("Firebase AI Logic invalid examples JSON response:", rawText)
            throw AIServiceError.invalidResponse
        }

        do {
            let response = try JSONDecoder().decode(GeneratedExampleResponse.self, from: data)
            let example = GeneratedSlangExample(
                sentence: response.example.sentence.trimmingCharacters(in: .whitespacesAndNewlines),
                meaning: response.example.meaning.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            guard !example.sentence.isEmpty, !example.meaning.isEmpty else {
                throw AIServiceError.emptyResponse
            }

            return example
        } catch let error as AIServiceError {
            throw error
        } catch {
            print("Firebase AI Logic invalid examples JSON response:", rawText)
            throw AIServiceError.invalidResponse
        }
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

    private func validatedNotes(_ notes: [DecodeNote], sourceText: String) -> [DecodeNote] {
        let normalizedSourceText = normalizeForContainment(sourceText)
        var seenExpressions = Set<String>()
        let validNotes = notes.filter { note in
            let normalizedExpression = normalizeForContainment(note.originalExpression)

            guard !normalizedExpression.isEmpty,
                  !isTooBroadExpression(note.originalExpression, sourceText: sourceText),
                  !isGenericExplanation(note.meaning),
                  !isTooBasicTargetExpression(note.expression) else {
                return false
            }

            return seenExpressions.insert(normalizedExpression).inserted
        }

        let matchingNotes = validNotes.filter {
            normalizedSourceText.contains(normalizeForContainment($0.originalExpression))
        }

        return matchingNotes.isEmpty ? validNotes : matchingNotes
    }

    private func isTooBroadExpression(_ expression: String, sourceText: String) -> Bool {
        let normalizedExpression = normalizeForContainment(expression)
        let normalizedSourceText = normalizeForContainment(sourceText)
        let sourceHasMultipleChunks = sourceText
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count > 1
        let expressionWordCount = expression
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count
        let sourceCount = normalizedSourceText.count
        let expressionCount = normalizedExpression.count

        if expressionWordCount > 4 {
            return true
        }

        if expressionCount > 24 {
            return true
        }

        if normalizedExpression == normalizedSourceText {
            return sourceHasMultipleChunks || sourceCount > 6
        }

        return sourceCount >= 8
            && expressionCount >= Int(Double(sourceCount) * 0.72)
    }

    private func isGenericExplanation(_ meaning: String) -> Bool {
        let normalizedMeaning = meaning.lowercased()
        let genericFragments = [
            "colloquial expression",
            "emotional intensity",
            "formal statement",
            "professional or serious",
            "serious communication",
            "reframed",
            "translated the"
        ]

        return genericFragments.contains { normalizedMeaning.contains($0) }
    }

    private func isTooBasicTargetExpression(_ expression: String) -> Bool {
        let normalizedExpression = normalizeForContainment(expression)
        let basicExpressions = Set([
            "really",
            "very",
            "so",
            "actually",
            "just",
            "thing",
            "things",
            "good",
            "bad",
            "yes",
            "no",
            "okay",
            "ok"
        ])

        return basicExpressions.contains(normalizedExpression)
    }

    private func normalizeForContainment(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty }
            .joined()
    }
}

private struct GeneratedExampleResponse: Decodable {
    let example: GeneratedSlangExample
}

private struct RawDecodeResult: Decodable {
    let result: String
    let notes: [RawDecodeNote]

    private enum CodingKeys: String, CodingKey {
        case result
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        result = try container.decode(String.self, forKey: .result)
        notes = try container.decodeIfPresent([RawDecodeNote].self, forKey: .notes) ?? []
    }
}

private struct RawDecodeNote: Decodable {
    let sourceExpression: String
    let meaning: String
    let meaningLanguage: String?
    let translatedExpression: String

    private enum CodingKeys: String, CodingKey {
        case sourceExpression
        case meaning
        case meaningLanguage
        case translatedExpression
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sourceExpression = try container.decodeIfPresent(String.self, forKey: .sourceExpression) ?? ""
        meaning = try container.decodeIfPresent(String.self, forKey: .meaning) ?? ""
        meaningLanguage = try container.decodeIfPresent(String.self, forKey: .meaningLanguage)
        translatedExpression = try container.decodeIfPresent(String.self, forKey: .translatedExpression) ?? ""
    }
}
