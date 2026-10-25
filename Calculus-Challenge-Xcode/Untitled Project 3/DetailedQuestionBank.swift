import Foundation

enum DetailedQuestionBank {
    static func load() -> [CalculusQuestion] {
        guard
            let url = Bundle.main.url(
                forResource: "Calculus_1000_Advanced_Detailed_Solutions",
                withExtension: "md"
            ),
            let markdown = try? String(contentsOf: url, encoding: .utf8)
        else {
            return []
        }

        var questions: [CalculusQuestion] = []

        for section in markdown.components(separatedBy: "\n### Question ").dropFirst() {
            if let question = parseQuestion(section) {
                questions.append(question)
            }
        }

        return questions.sorted { $0.id < $1.id }
    }

    private static func parseQuestion(_ section: String) -> CalculusQuestion? {
        guard
            let headerEnd = section.firstIndex(of: "\n"),
            let upgradedRange = section.range(of: "**Advanced problem**:"),
            let detailRange = section.range(of: "**Detailed solution**")
        else {
            return nil
        }

        let header = String(section[..<headerEnd])
        let headerParts = header.components(separatedBy: "|")

        guard
            let idText = headerParts.first?
                .trimmingCharacters(in: .whitespacesAndNewlines),
            let id = Int(idText)
        else {
            return nil
        }

        let categoryName = headerParts.count > 1
            ? headerParts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            : ""

        let promptMarkdown = String(
            section[upgradedRange.upperBound..<detailRange.lowerBound]
        )
        let solutionStart = detailRange.upperBound
        let solutionMarkdown = String(section[solutionStart...])
            .components(separatedBy: "\n---")
            .first ?? ""

        return CalculusQuestion(
            id: id,
            category: category(for: categoryName),
            difficulty: .hard,
            question: latexContent(promptMarkdown),
            answer: answerContent(from: solutionMarkdown),
            explanation: latexContent(solutionMarkdown)
        )
    }

    private static func category(for name: String) -> CalculusCategory {
        switch name {
        case "Limits and Continuity":
            .limitsAndContinuity
        case "Differentiation Rules":
            .derivatives
        case "Applications of Derivatives":
            .derivativeApplications
        case "Basic Integration":
            .basicIntegrals
        case "Integration Techniques":
            .integrationTechniques
        case "Applications of Integration":
            .integralApplications
        case "Differential Equations":
            .differentialEquations
        case "Sequences and Series":
            .sequencesAndSeries
        case "Parametric and Polar Calculus":
            .parametricAndPolar
        case "Multiple and Vector Calculus":
            .multipleAndVector
        default:
            .multivariable
        }
    }

    private static func latexContent(_ markdown: String) -> String {
        markdown
            .replacingOccurrences(of: "\\boxed{", with: "{")
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "---", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func answerContent(from solution: String) -> String {
        let parts = solution.components(separatedBy: "$$")
        let displayMath = stride(from: 1, to: parts.count, by: 2).map { index in
            parts[index].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let boxedMath = displayMath.filter { $0.contains("\\boxed{") }
        let selected = (boxedMath.last ?? displayMath.last ?? "See the detailed solution.")
            .replacingOccurrences(of: "\\boxed{", with: "{")
        return "$$\(selected)$$"
    }
}
