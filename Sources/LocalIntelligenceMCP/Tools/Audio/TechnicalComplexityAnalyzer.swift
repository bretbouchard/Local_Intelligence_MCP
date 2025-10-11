//
//  TechnicalComplexityAnalyzer.swift
//  LocalIntelligenceMCP
//
//  Created on 2025-10-09.
//

import Foundation

/// Analyzes technical complexity of audio content
public class TechnicalComplexityAnalyzer {

    // MARK: - Properties

    private let technicalTerms: Set<String>
    private let equipmentBrands: Set<String>
    private let softwareTools: Set<String>
    private let technicalParameters: [String: String]

    // MARK: - Initialization

    public init() {
        self.technicalTerms = [
            "frequency", "spectrum", "compression", "eq", "equalization",
            "threshold", "ratio", "attack", "release", "makeup gain",
            "khz", "hz", "db", "decibel", "bit depth", "sample rate",
            "latency", "buffer", "driver", "interface", "preamp",
            "reverb", "delay", "chorus", "flanger", "phaser",
            "automation", "plugin", "vst", "au", "aax",
            "mono", "stereo", "surround", "phase", "clipping",
            "saturation", "distortion", "limiting", "gating", "expansion",
            "mid", "side", "ms processing", "parallel", "serial",
            "convolution", "impulse response", "ir", "sampling",
            "quantization", "dithering", "noise shaping", "aliasing",
            "oversampling", "interpolation", "anti-aliasing"
        ]

        self.equipmentBrands = [
            "neumann", "akg", "sennheiser", "shure", "audio-technica", "rode",
            "api", "neve", "ssl", "focusrite", "universal audio", "manley",
            "chandler", "great river", "thermann", "aurora", "lynx",
            "genelec", "yamaha", "adam", "focal", "krk", "dynaudio",
            "alesis", "alesis", "behringer", "mackie", "soundcraft", "allen & heath"
        ]

        self.softwareTools = [
            "pro tools", "logic pro", "ableton live", "cubase", "studio one",
            "waves", "fabfilter", "soundtoys", "valhalla", "native instruments",
            "izotope", "celemony", "steinberg", "avid", "apple", "serato",
            "reaper", "bitwig", "fl studio", "reason", "mixbus"
        ]

        self.technicalParameters = [
            "frequency": #"(\d+(?:\.\d+)?)\s*hz"#,
            "khz": #"(\d+(?:\.\d+)?)\s*khz"#,
            "db": #"(-?\d+(?:\.\d+)?)\s*db"#,
            "ratio": #"(\d+(?:\.\d+)?)\s*:\s*\d+"#,
            "threshold": #"(-?\d+(?:\.\d+)?)\s*db"#,
            "attack": #"(\d+(?:\.\d+)?)\s*ms"#,
            "release": #"(\d+(?:\.\d+)?)\s*ms"#,
            "bit depth": #"(\d+)\s*bit"#,
            "sample rate": #"(\d+(?:\.\d+)?)\s*khz"#,
            "buffer": #"(\d+)\s*samples?"#,
            "latency": #"(\d+(?:\.\d+)?)\s*ms"#
        ]
    }

    // MARK: - Main Analysis Method

    /// Analyzes technical complexity of content
    /// - Parameter content: Content to analyze
    /// - Returns: Technical complexity assessment
    public func analyzeComplexity(content: String) -> TechnicalComplexity {
        let lowercaseContent = content.lowercased()

        // Extract technical terms
        let technicalTermsFound = extractTechnicalTerms(from: lowercaseContent)

        // Extract equipment
        let equipmentFound = extractEquipment(from: lowercaseContent)

        // Extract software
        let softwareFound = extractSoftware(from: lowercaseContent)

        // Extract parameters
        let parameters = extractParameters(from: content)

        // Calculate complexity score
        let complexityScore = calculateComplexityScore(
            content: content,
            technicalTerms: technicalTermsFound,
            equipment: equipmentFound,
            software: softwareFound,
            parameters: parameters
        )

        // Determine complexity level
        let level = determineComplexityLevel(score: complexityScore)

        return TechnicalComplexity(
            level: level,
            technicalTerms: Array(technicalTermsFound),
            equipment: Array(equipmentFound),
            software: Array(softwareFound),
            parameters: parameters,
            complexityScore: complexityScore
        )
    }

    /// Provides detailed complexity analysis with breakdown
    /// - Parameter content: Content to analyze
    /// - Returns: Detailed complexity analysis
    public func getDetailedComplexityAnalysis(content: String) -> DetailedComplexityAnalysis {
        let lowercaseContent = content.lowercased()

        // Extract all technical elements
        let technicalTermsFound = extractTechnicalTerms(from: lowercaseContent)
        let equipmentFound = extractEquipment(from: lowercaseContent)
        let softwareFound = extractSoftware(from: lowercaseContent)
        let parameters = extractParameters(from: content)

        // Calculate individual scores
        let technicalDensityScore = calculateTechnicalDensityScore(
            content: content,
            technicalTerms: technicalTermsFound
        )
        let equipmentScore = calculateEquipmentScore(equipment: equipmentFound)
        let softwareScore = calculateSoftwareScore(software: softwareFound)
        let parameterScore = calculateParameterScore(parameters: parameters)

        // Calculate overall complexity score
        let overallScore = min(
            technicalDensityScore + equipmentScore + softwareScore + parameterScore,
            1.0
        )

        // Determine complexity level
        let level = determineComplexityLevel(score: overallScore)

        // Generate recommendations
        let recommendations = generateComplexityRecommendations(
            level: level,
            technicalTerms: technicalTermsFound,
            equipment: equipmentFound,
            software: softwareFound,
            parameters: parameters
        )

        return DetailedComplexityAnalysis(
            content: content,
            overallScore: overallScore,
            level: level,
            technicalTerms: Array(technicalTermsFound),
            equipment: Array(equipmentFound),
            software: Array(softwareFound),
            parameters: parameters,
            scoreBreakdown: ComplexityScoreBreakdown(
                technicalDensity: technicalDensityScore,
                equipment: equipmentScore,
                software: softwareScore,
                parameters: parameterScore
            ),
            recommendations: recommendations
        )
    }

    // MARK: - Extraction Methods

    /// Extracts technical terms from content
    /// - Parameter content: Content to analyze
    /// - Returns: Set of technical terms found
    private func extractTechnicalTerms(from content: String) -> Set<String> {
        var foundTerms: Set<String> = []

        // Direct term matching
        for term in technicalTerms {
            if content.contains(term) {
                foundTerms.insert(term)
            }
        }

        // Pattern-based term matching
        let patterns = [
            #"\d+\s*hz"#,
            #"\d+\s*khz"#,
            #"-?\d+\s*db"#,
            #"\d+:\d+\s*ratio"#,
            #"\d+\s*bit"#,
            #"\d+/\d+"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(content.startIndex..<content.endIndex, in: content)
                let matches = regex.matches(in: content, range: range)

                if !matches.isEmpty {
                    // Add a generic term based on the pattern
                    if pattern.contains("hz") {
                        foundTerms.insert("frequency")
                    } else if pattern.contains("db") {
                        foundTerms.insert("decibel")
                    } else if pattern.contains("ratio") {
                        foundTerms.insert("compression")
                    } else if pattern.contains("bit") {
                        foundTerms.insert("bit depth")
                    }
                }
            }
        }

        return foundTerms
    }

    /// Extracts equipment brands from content
    /// - Parameter content: Content to analyze
    /// - Returns: Set of equipment brands found
    private func extractEquipment(from content: String) -> Set<String> {
        var foundEquipment: Set<String> = []

        for brand in equipmentBrands {
            if content.contains(brand) {
                foundEquipment.insert(brand)
            }
        }

        return foundEquipment
    }

    /// Extracts software tools from content
    /// - Parameter content: Content to analyze
    /// - Returns: Set of software tools found
    private func extractSoftware(from content: String) -> Set<String> {
        var foundSoftware: Set<String> = []

        for software in softwareTools {
            if content.contains(software) {
                foundSoftware.insert(software)
            }
        }

        return foundSoftware
    }

    /// Extracts technical parameters from content
    /// - Parameter content: Content to analyze
    /// - Returns: Dictionary of parameter names and values
    private func extractParameters(from content: String) -> [String: String] {
        var parameters: [String: String] = [:]

        for (parameterName, pattern) in technicalParameters {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(content.startIndex..<content.endIndex, in: content)

                if let match = regex.firstMatch(in: content, range: range) {
                    if match.numberOfRanges > 1,
                       let valueRange = Range(match.range(at: 1), in: content) {
                        let value = String(content[valueRange])
                        parameters[parameterName] = value
                    }
                }
            }
        }

        return parameters
    }

    // MARK: - Scoring Methods

    /// Calculates overall complexity score
    /// - Parameters:
    ///   - content: Content being analyzed
    ///   - technicalTerms: Technical terms found
    ///   - equipment: Equipment found
    ///   - software: Software found
    ///   - parameters: Parameters found
    /// - Returns: Overall complexity score (0.0-1.0)
    private func calculateComplexityScore(
        content: String,
        technicalTerms: Set<String>,
        equipment: Set<String>,
        software: Set<String>,
        parameters: [String: String]
    ) -> Double {
        let technicalDensityScore = calculateTechnicalDensityScore(
            content: content,
            technicalTerms: technicalTerms
        )
        let equipmentScore = calculateEquipmentScore(equipment: equipment)
        let softwareScore = calculateSoftwareScore(software: software)
        let parameterScore = calculateParameterScore(parameters: parameters)

        return min(technicalDensityScore + equipmentScore + softwareScore + parameterScore, 1.0)
    }

    /// Calculates technical density score
    /// - Parameters:
    ///   - content: Content being analyzed
    ///   - technicalTerms: Technical terms found
    /// - Returns: Technical density score (0.0-0.4)
    private func calculateTechnicalDensityScore(content: String, technicalTerms: Set<String>) -> Double {
        let wordCount = Double(content.split(separator: " ").count)
        let technicalDensity = Double(technicalTerms.count) / wordCount
        return min(technicalDensity * 10, 0.4) // Max 0.4 for technical density
    }

    /// Calculates equipment score
    /// - Parameter equipment: Equipment found
    /// - Returns: Equipment score (0.0-0.2)
    private func calculateEquipmentScore(equipment: Set<String>) -> Double {
        return min(Double(equipment.count) * 0.05, 0.2) // Max 0.2 for equipment
    }

    /// Calculates software score
    /// - Parameter software: Software found
    /// - Returns: Software score (0.0-0.15)
    private func calculateSoftwareScore(software: Set<String>) -> Double {
        return min(Double(software.count) * 0.05, 0.15) // Max 0.15 for software
    }

    /// Calculates parameter score
    /// - Parameter parameters: Parameters found
    /// - Returns: Parameter score (0.0-0.25)
    private func calculateParameterScore(parameters: [String: String]) -> Double {
        return min(Double(parameters.count) * 0.05, 0.25) // Max 0.25 for parameters
    }

    /// Determines complexity level based on score
    /// - Parameter score: Complexity score (0.0-1.0)
    /// - Returns: Complexity level
    private func determineComplexityLevel(score: Double) -> ComplexityLevel {
        switch score {
        case 0..<0.2:
            return .basic
        case 0.2..<0.4:
            return .intermediate
        case 0.4..<0.6:
            return .advanced
        case 0.6..<0.8:
            return .professional
        default:
            return .expert
        }
    }

    /// Generates complexity recommendations
    /// - Parameters:
    ///   - level: Complexity level
    ///   - technicalTerms: Technical terms found
    ///   - equipment: Equipment found
    ///   - software: Software found
    ///   - parameters: Parameters found
    /// - Returns: Array of recommendations
    private func generateComplexityRecommendations(
        level: ComplexityLevel,
        technicalTerms: Set<String>,
        equipment: Set<String>,
        software: Set<String>,
        parameters: [String: String]
    ) -> [String] {
        var recommendations: [String] = []

        switch level {
        case .basic:
            recommendations.append("Content is suitable for beginners with minimal technical background")
            if technicalTerms.isEmpty {
                recommendations.append("Consider adding more technical details for comprehensive documentation")
            }
        case .intermediate:
            recommendations.append("Content appropriate for users with basic technical knowledge")
            if equipment.isEmpty && software.isEmpty {
                recommendations.append("Consider mentioning specific equipment or software for clarity")
            }
        case .advanced:
            recommendations.append("Content requires intermediate to advanced technical understanding")
            if parameters.count < 3 {
                recommendations.append("Consider adding more specific parameter settings for reproducibility")
            }
        case .professional:
            recommendations.append("Content suitable for professional audio engineers and technicians")
            recommendations.append("Ensure all technical terms and parameters are clearly defined")
        case .expert:
            recommendations.append("Content contains highly specialized technical information")
            recommendations.append("Consider providing additional context or explanations for broader accessibility")
            recommendations.append("Document any non-standard techniques or proprietary information")
        }

        // Specific recommendations based on content analysis
        if !equipment.isEmpty && !software.isEmpty {
            recommendations.append("Good balance of equipment and software references")
        } else if !equipment.isEmpty && software.isEmpty {
            recommendations.append("Consider mentioning software tools used with the equipment")
        } else if equipment.isEmpty && !software.isEmpty {
            recommendations.append("Consider mentioning hardware equipment used with the software")
        }

        if parameters.count > 5 {
            recommendations.append("Comprehensive parameter documentation - consider organizing in tables")
        }

        return recommendations
    }
}

// MARK: - Supporting Types

/// Detailed complexity analysis result
public struct DetailedComplexityAnalysis {
    public let content: String
    public let overallScore: Double
    public let level: ComplexityLevel
    public let technicalTerms: [String]
    public let equipment: [String]
    public let software: [String]
    public let parameters: [String: String]
    public let scoreBreakdown: ComplexityScoreBreakdown
    public let recommendations: [String]

    public init(
        content: String,
        overallScore: Double,
        level: ComplexityLevel,
        technicalTerms: [String],
        equipment: [String],
        software: [String],
        parameters: [String: String],
        scoreBreakdown: ComplexityScoreBreakdown,
        recommendations: [String]
    ) {
        self.content = content
        self.overallScore = overallScore
        self.level = level
        self.technicalTerms = technicalTerms
        self.equipment = equipment
        self.software = software
        self.parameters = parameters
        self.scoreBreakdown = scoreBreakdown
        self.recommendations = recommendations
    }
}

/// Complexity score breakdown
public struct ComplexityScoreBreakdown {
    public let technicalDensity: Double
    public let equipment: Double
    public let software: Double
    public let parameters: Double

    public init(technicalDensity: Double, equipment: Double, software: Double, parameters: Double) {
        self.technicalDensity = technicalDensity
        self.equipment = equipment
        self.software = software
        self.parameters = parameters
    }

    /// Total score (sum of all components)
    public var total: Double {
        return technicalDensity + equipment + software + parameters
    }

    /// Percentage breakdown of each component
    public var percentages: [String: Double] {
        let total = self.total
        guard total > 0 else { return [:] }

        return [
            "technicalDensity": (technicalDensity / total) * 100,
            "equipment": (equipment / total) * 100,
            "software": (software / total) * 100,
            "parameters": (parameters / total) * 100
        ]
    }
}