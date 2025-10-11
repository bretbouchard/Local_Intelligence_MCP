//
//  CodeQualityStandards.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Code quality standards and guidelines for Local Intelligence MCP Tools
/// Provides standardized patterns for maintaining high code quality
public struct CodeQualityStandards {

    // MARK: - File Organization Standards

    /// Maximum recommended file size
    public static let maxFileSizeLines = 500

    /// Maximum recommended function length
    public static let maxFunctionLengthLines = 30

    /// Maximum recommended cyclomatic complexity
    public static let maxCyclomaticComplexity = 10

    /// Required documentation coverage for public APIs
    public static let minDocumentationCoverage = 0.8

    // MARK: - Documentation Standards

    /// Standard documentation template for public methods
    public static func methodDocumentationTemplate(
        methodName: String,
        parameters: [String],
        returns: String?,
        description: String,
        examples: [String] = []
    ) -> String {
        var doc = "/// \(description)\n"
        doc += "///\n"

        if !parameters.isEmpty {
            doc += "/// - Parameters:\n"
            for param in parameters {
                doc += "///   - \(param): Description of the parameter\n"
            }
            doc += "///\n"
        }

        if let returns = returns {
            doc += "/// - Returns: \(returns)\n"
            doc += "///\n"
        }

        if !examples.isEmpty {
            doc += "/// - Examples:\n"
            for example in examples {
                doc += "///   ```swift\n"
                doc += "///   \(example)\n"
                doc += "///   ```\n"
            }
            doc += "///\n"
        }

        return doc
    }

    /// Standard documentation template for types
    public static func typeDocumentationTemplate(
        typeName: String,
        description: String,
        usage: String? = nil,
        examples: [String] = []
    ) -> String {
        var doc = "/// \(description)\n"
        doc += "///\n"

        if let usage = usage {
            doc += "/// Usage:\n"
            doc += "/// ```swift\n"
            doc += "/// \(usage)\n"
            doc += "/// ```\n"
            doc += "///\n"
        }

        if !examples.isEmpty {
            doc += "/// Examples:\n"
            for example in examples {
                doc += "/// ```swift\n"
                doc += "/// \(example)\n"
                doc += "/// ```\n"
            }
        }

        return doc
    }

    // MARK: - Naming Conventions

    /// Audio domain-specific naming conventions
    public enum AudioNamingConventions {

        /// Standard prefixes for audio-related variables
        public static let audioPrefixes = [
            "audio", "sound", "signal", "wave", "track"
        ]

        /// Standard suffixes for audio-related types
        public static let audioSuffixes = [
            "Audio", "Sound", "Signal", "Wave", "Track", "Processor"
        ]

        /// Common audio domain abbreviations
        public static let audioAbbreviations: [String: String] = [
            "kHz": "kilohertz",
            "Hz": "hertz",
            "dB": "decibel",
            "EQ": "equalization",
            "DAW": "digital audio workstation",
            "VST": "virtual studio technology",
            "AU": "audio unit",
            "AAX": "Avid audio extension",
            "MIDI": "musical instrument digital interface"
        ]
    }

    /// Validates naming conventions
    /// - Parameter identifier: The identifier to validate
    /// - Returns: Validation result with suggestions
    public static func validateNaming(_ identifier: String) -> NamingValidationResult {
        var issues: [String] = []
        var suggestions: [String] = [identifier]

        // Check for camelCase compliance
        if !identifier.isCamelCase {
            issues.append("Should use camelCase naming convention")
            suggestions.append(identifier.toCamelCase)
        }

        // Check length
        if identifier.count > 50 {
            issues.append("Identifier is too long (>50 characters)")
            suggestions.append(String(identifier.prefix(45)))
        }

        // Check for abbreviations
        if identifier.contains(where: { $0.isUppercase && $0.isLetter }) && identifier.count < 5 {
            let expanded = AudioNamingConventions.audioAbbreviations[identifier.uppercased()]
            if let expanded = expanded {
                suggestions.append(expanded)
            }
        }

        return NamingValidationResult(
            identifier: identifier,
            isValid: issues.isEmpty,
            issues: issues,
            suggestions: suggestions
        )
    }

    // MARK: - Code Complexity Analysis

    /// Analyzes function complexity
    /// - Parameter functionCode: Source code of the function
    /// - Returns: Complexity analysis result
    public static func analyzeComplexity(_ functionCode: String) -> ComplexityAnalysisResult {
        let lines = functionCode.components(separatedBy: .newlines)
        let lineCount = lines.count

        // Count complexity indicators
        let complexityIndicators = [
            "if", "else", "guard", "for", "while", "switch", "case",
            "&&", "||", "??", "try", "catch", "throw", "return"
        ]

        var complexityScore = 1 // Base complexity
        for line in lines {
            for indicator in complexityIndicators {
                complexityScore += line.components(separatedBy: .whitespaces)
                    .filter { $0 == indicator }
                    .count
            }
        }

        // Check nesting level
        let nestingLevel = calculateNestingLevel(functionCode)
        complexityScore += nestingLevel

        // Determine complexity level
        let level: ComplexityAnalysisLevel
        switch complexityScore {
        case 1...5:
            level = .simple
        case 6...10:
            level = .moderate
        case 11...20:
            level = .complex
        default:
            level = .veryComplex
        }

        return ComplexityAnalysisResult(
            lineCount: lineCount,
            complexityScore: complexityScore,
            level: level,
            nestingLevel: nestingLevel,
            indicators: complexityIndicators
        )
    }

    /// Calculates nesting level in code
    private static func calculateNestingLevel(_ code: String) -> Int {
        var maxNesting = 0
        var currentNesting = 0

        for character in code {
            if character == "{" {
                currentNesting += 1
                maxNesting = max(maxNesting, currentNesting)
            } else if character == "}" {
                currentNesting -= 1
            }
        }

        return maxNesting
    }

    // MARK: - Documentation Coverage Analysis

    /// Analyzes documentation coverage
    /// - Parameter content: Source code to analyze
    /// - Parameter publicAPIs: List of public API elements
    /// - Returns: Documentation coverage result
    public static func analyzeDocumentationCoverage(
        _ content: String,
        publicAPIs: [String]
    ) -> DocumentationCoverageResult {
        var documentedAPIs: [String] = []
        var undocumentedAPIs: [String] = []

        for api in publicAPIs {
            let pattern = "///.*\\b\(api)\\b"
            if content.range(of: pattern, options: .regularExpression) != nil {
                documentedAPIs.append(api)
            } else {
                undocumentedAPIs.append(api)
            }
        }

        let coverage = Double(documentedAPIs.count) / Double(publicAPIs.count)

        return DocumentationCoverageResult(
            totalAPIs: publicAPIs.count,
            documentedAPIs: documentedAPIs,
            undocumentedAPIs: undocumentedAPIs,
            coveragePercentage: coverage
        )
    }

    // MARK: - Code Duplication Detection

    /// Detects code duplication
    /// - Parameter files: List of files to analyze
    /// - Returns: Duplication analysis result
    public static func detectCodeDuplication(_ files: [String]) -> DuplicationAnalysisResult {
        // This is a simplified implementation
        // In practice, you'd use more sophisticated similarity algorithms

        var duplicateBlocks: [DuplicateBlock] = []
        var totalLines = 0

        for file in files {
            let lines = file.components(separatedBy: .newlines)
            totalLines += lines.count

            // Simple duplication detection based on line similarity
            for i in 0..<lines.count {
                for j in i+1..<min(i + 10, lines.count) {
                    let similarity = calculateLineSimilarity(lines[i], lines[j])
                    if similarity > 0.8 {
                        duplicateBlocks.append(DuplicateBlock(
                            line1: i + 1,
                            line2: j + 1,
                            content: lines[i],
                            similarity: similarity
                        ))
                    }
                }
            }
        }

        let duplicationPercentage = Double(duplicateBlocks.count) / Double(totalLines) * 100

        return DuplicationAnalysisResult(
            totalLines: totalLines,
            duplicateBlocks: duplicateBlocks,
            duplicationPercentage: duplicationPercentage
        )
    }

    /// Calculates similarity between two lines of code
    private static func calculateLineSimilarity(_ line1: String, _ line2: String) -> Double {
        let words1 = Set(line1.lowercased().components(separatedBy: .whitespaces))
        let words2 = Set(line2.lowercased().components(separatedBy: .whitespaces))

        let intersection = words1.intersection(words2)
        let union = words1.union(words2)

        return union.isEmpty ? 1.0 : Double(intersection.count) / Double(union.count)
    }
}

// MARK: - Supporting Types

/// Naming validation result
public struct NamingValidationResult {
    public let identifier: String
    public let isValid: Bool
    public let issues: [String]
    public let suggestions: [String]
}

/// Complexity analysis result
public struct ComplexityAnalysisResult {
    public let lineCount: Int
    public let complexityScore: Int
    public let level: ComplexityAnalysisLevel
    public let nestingLevel: Int
    public let indicators: [String]
}

/// Complexity level for analysis
public enum ComplexityAnalysisLevel {
    case simple
    case moderate
    case complex
    case veryComplex

    public var description: String {
        switch self {
        case .simple: return "Simple (1-5 complexity points)"
        case .moderate: return "Moderate (6-10 complexity points)"
        case .complex: return "Complex (11-20 complexity points)"
        case .veryComplex: return "Very Complex (>20 complexity points)"
        }
    }
}


/// Documentation coverage result
public struct DocumentationCoverageResult {
    public let totalAPIs: Int
    public let documentedAPIs: [String]
    public let undocumentedAPIs: [String]
    public let coveragePercentage: Double
}

/// Duplicate block information
public struct DuplicateBlock {
    public let line1: Int
    public let line2: Int
    public let content: String
    public let similarity: Double
}

/// Duplication analysis result
public struct DuplicationAnalysisResult {
    public let totalLines: Int
    public let duplicateBlocks: [DuplicateBlock]
    public let duplicationPercentage: Double
}

// MARK: - String Extensions

extension String {

    /// Checks if string follows camelCase naming convention
    var isCamelCase: Bool {
        guard !isEmpty else { return false }

        let firstChar = prefix(1)
        let rest = dropFirst()

        // First character should be lowercase
        guard firstChar.range(of: "[a-z]") != nil else { return false }

        // Rest should not contain underscores or spaces
        return !rest.contains("_") && !rest.contains(" ")
    }

    /// Converts string to camelCase
    var toCamelCase: String {
        guard !isEmpty else { return self }

        let components = components(separatedBy: .whitespacesAndNewlines)
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }

        guard !components.isEmpty else { return "" }

        return components.first!.lowercased() + components.dropFirst().joined()
    }
}

// MARK: - Quality Metrics

/// Overall code quality metrics
public struct CodeQualityMetrics {
    public let fileCount: Int
    public let averageFileSize: Double
    public let averageFunctionLength: Double
    public let averageComplexity: Double
    public let documentationCoverage: Double
    public let duplicationPercentage: Double
    public let qualityScore: Double

    public init(
        fileCount: Int,
        averageFileSize: Double,
        averageFunctionLength: Double,
        averageComplexity: Double,
        documentationCoverage: Double,
        duplicationPercentage: Double
    ) {
        self.fileCount = fileCount
        self.averageFileSize = averageFileSize
        self.averageFunctionLength = averageFunctionLength
        self.averageComplexity = averageComplexity
        self.documentationCoverage = documentationCoverage
        self.duplicationPercentage = duplicationPercentage

        // Calculate overall quality score (0-100)
        let sizeScore = max(0, 100 - (averageFileSize - 200) / 5)
        let complexityScore = max(0, 100 - (averageComplexity - 5) * 5)
        let docScore = documentationCoverage * 100
        let duplicationScore = max(0, 100 - duplicationPercentage * 10)

        self.qualityScore = (sizeScore + complexityScore + docScore + duplicationScore) / 4
    }

    /// Returns quality grade
    public var qualityGrade: QualityGrade {
        switch qualityScore {
        case 90...100: return .excellent
        case 80..<90: return .good
        case 70..<80: return .fair
        case 60..<70: return .needsImprovement
        default: return .poor
        }
    }
}

/// Quality grade
public enum QualityGrade {
    case excellent
    case good
    case fair
    case needsImprovement
    case poor

    public var description: String {
        switch self {
        case .excellent: return "Excellent (90-100)"
        case .good: return "Good (80-89)"
        case .fair: return "Fair (70-79)"
        case .needsImprovement: return "Needs Improvement (60-69)"
        case .poor: return "Poor (<60)"
        }
    }
}