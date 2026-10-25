import SwiftUI

enum CalculusCategory: String {
    case limitsAndContinuity = "Limits & Continuity"
    case derivatives = "Derivative Rules"
    case derivativeApplications = "Applications of Derivatives"
    case basicIntegrals = "Basic Integration"
    case integrationTechniques = "Integration Techniques"
    case integralApplications = "Applications of Integration"
    case differentialEquations = "Differential Equations"
    case sequencesAndSeries = "Sequences & Series"
    case parametricAndPolar = "Parametric & Polar"
    case multivariable = "Multivariable Calculus"
    case multipleAndVector = "Multiple & Vector Calculus"

    var iconName: String {
        switch self {
        case .limitsAndContinuity:
            "chart.xyaxis.line"
        case .derivatives:
            "function"
        case .derivativeApplications:
            "arrow.up.right"
        case .basicIntegrals:
            "sum"
        case .integrationTechniques:
            "square.stack.3d.up"
        case .integralApplications:
            "ruler"
        case .differentialEquations:
            "waveform.path.ecg"
        case .sequencesAndSeries:
            "list.number"
        case .parametricAndPolar:
            "circle.grid.cross"
        case .multivariable:
            "cube.transparent"
        case .multipleAndVector:
            "move.3d"
        }
    }

    var color: Color {
        switch self {
        case .limitsAndContinuity, .sequencesAndSeries:
            .indigo
        case .derivatives, .multivariable:
            .blue
        case .derivativeApplications, .parametricAndPolar:
            .purple
        case .basicIntegrals, .integrationTechniques:
            .orange
        case .integralApplications, .multipleAndVector:
            .teal
        case .differentialEquations:
            .pink
        }
    }
}

enum QuestionDifficulty: String {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var color: Color {
        switch self {
        case .easy:
            .green
        case .medium:
            .orange
        case .hard:
            .red
        }
    }
}

struct CalculusQuestion: Identifiable, Equatable {
    let id: Int
    let category: CalculusCategory
    let difficulty: QuestionDifficulty
    let question: String
    let answer: String
    let explanation: String

    var choices: [AnswerChoice] {
        let expression = answer
            .replacingOccurrences(of: "$$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var candidates = [expression]
        let proposedDistractors = [
            swappedOperators(in: expression),
            omittedChainFactor(in: expression),
            changedCoefficient(in: expression)
        ]

        for candidate in proposedDistractors where !candidates.contains(candidate) {
            candidates.append(candidate)
        }
        while candidates.count < 4 {
            candidates.append(expression + "+" + String(candidates.count))
        }

        let correctPosition = id % 4
        var ordered = Array(candidates.dropFirst().prefix(3))
        ordered.insert(expression, at: correctPosition)

        return ordered.enumerated().map { position, text in
            AnswerChoice(
                id: position,
                text: "$$" + text + "$$",
                isCorrect: text == expression
            )
        }
    }

    private func swappedOperators(in expression: String) -> String {
        expression
            .replacingOccurrences(of: "+", with: "§")
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "§", with: "-")
    }

    private func omittedChainFactor(in expression: String) -> String {
        if expression.contains("P") {
            return replacingMathVariable("P", with: "A", in: expression)
        }
        if expression.contains("Q") {
            return replacingMathVariable("Q", with: "P", in: expression)
        }
        return expression.replacingOccurrences(
            of: "(?<![A-Za-z\\\\])x(?![A-Za-z^])",
            with: "x^2",
            options: .regularExpression
        )
    }

    private func replacingMathVariable(
        _ variable: String,
        with replacement: String,
        in expression: String
    ) -> String {
        expression.replacingOccurrences(
            of: "(?<![A-Za-z\\\\])\(variable)(?![A-Za-z])",
            with: replacement,
            options: .regularExpression
        )
    }

    private func changedCoefficient(in expression: String) -> String {
        for (original, replacement) in [("2", "3"), ("3", "2"), ("1", "2")] {
            if let range = expression.range(of: original) {
                var changed = expression
                changed.replaceSubrange(range, with: replacement)
                return changed
            }
        }
        return expression + "+1"
    }
}

struct AnswerChoice: Identifiable, Equatable {
    let id: Int
    let text: String
    let isCorrect: Bool
}

struct ContentView: View {
    private static let questionBank = CalculusQuestion.questionBank

    @State private var currentQuestion: CalculusQuestion?
    @State private var isAnswerVisible = false
    @State private var selectedChoiceID: Int?
    @State private var isShowingLobby = true

    private let questions: [CalculusQuestion]

    init() {
        questions = Self.questionBank
        _currentQuestion = State(initialValue: nil)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    .black,
                    Color(white: 0.025),
                    Color.indigo.opacity(0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if isShowingLobby {
                LobbyView {
                    selectRandomQuestion()
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowingLobby = false
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(spacing: 24) {
                            HStack {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isShowingLobby = true
                                    }
                                } label: {
                                    Label("Lobby", systemImage: "house.fill")
                                }
                                .buttonStyle(.bordered)
                                .tint(.indigo)

                                Spacer()
                            }

                            AppHeader()
                                .id("pageTop")

                    if let currentQuestion {
                        QuestionCard(
                            category: currentQuestion.category,
                            difficulty: currentQuestion.difficulty,
                            question: currentQuestion.question
                        )
                        .transition(.scale(scale: 0.94).combined(with: .opacity))

                        AnswerSection(
                            answer: currentQuestion.answer,
                            explanation: currentQuestion.explanation,
                            choices: currentQuestion.choices,
                            selectedChoiceID: $selectedChoiceID,
                            isVisible: isAnswerVisible,
                            onSelect: selectChoice,
                            onToggle: toggleAnswer
                        )
                    } else {
                        WelcomeCard()
                    }

                        RandomQuestionButton(
                            hasQuestion: currentQuestion != nil,
                            action: {
                                selectRandomQuestion()
                                withAnimation(.easeOut(duration: 0.25)) {
                                    scrollProxy.scrollTo("pageTop", anchor: .top)
                                }
                            }
                        )

                        SourceAttributionView()
                        }
                        .padding()
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func selectRandomQuestion() {
        let availableQuestions = questions.filter { $0.id != currentQuestion?.id }

        guard let nextQuestion = availableQuestions.randomElement() else {
            return
        }

        isAnswerVisible = false
        selectedChoiceID = nil
        currentQuestion = nextQuestion
    }

    private func selectChoice(_ choiceID: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            selectedChoiceID = choiceID
            isAnswerVisible = true
        }
    }

    private func toggleAnswer() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isAnswerVisible.toggle()
        }
    }
}

struct LobbyView: View {
    let onStart: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer(minLength: 30)

                Image(systemName: "function")
                    .font(.system(size: 54, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 112, height: 112)
                    .background(.indigo.gradient, in: RoundedRectangle(cornerRadius: 30))
                    .shadow(color: .indigo.opacity(0.45), radius: 24, y: 12)
                    .accessibilityHidden(true)

                VStack(spacing: 10) {
                    Text("Calculus Challenge")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)

                    Text("Advanced Calculus Practice Lobby")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    LobbyStat(value: "1,000", label: "Problems", icon: "books.vertical.fill")
                    LobbyStat(value: "11", label: "Topics", icon: "square.grid.2x2.fill")
                    LobbyStat(value: "4", label: "Choices", icon: "checklist")
                }

                Button(action: onStart) {
                    Label("Start Random Challenge", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.indigo)

                Spacer(minLength: 24)
            }
            .padding(24)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct LobbyStat: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 7) {
            Image(systemName: icon)
                .foregroundStyle(.indigo)
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
    }
}

struct AppHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "function")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(.indigo)
                .accessibilityHidden(true)

            Text("Calculus Challenge")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("1,000 advanced single-variable and multivariable problems")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.top, 12)
    }
}

struct WelcomeCard: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "dice.fill")
                .font(.largeTitle)
                .foregroundStyle(.white)
                .padding(18)
                .background(.indigo.gradient, in: Circle())
                .accessibilityHidden(true)

            Text("Ready for a challenge?")
                .font(.title2)
                .fontWeight(.bold)

            Text("Draw a random problem covering limits, applications, series, differential equations, and multivariable calculus.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.5), lineWidth: 1)
        }
    }
}

struct QuestionCard: View {
    let category: CalculusCategory
    let difficulty: QuestionDifficulty
    let question: String

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Label(category.rawValue, systemImage: category.iconName)
                    .font(.headline)
                    .foregroundStyle(category.color)

                Spacer()

                Text(difficulty.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(difficulty.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(difficulty.color.opacity(0.12), in: Capsule())
            }

            Divider()

            Text("Problem")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            MathProblemView(question: question)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(category.color.opacity(0.25), lineWidth: 1.5)
        }
        .shadow(color: category.color.opacity(0.12), radius: 16, y: 8)
        .accessibilityElement(children: .combine)
    }
}

struct MathProblemView: View {
    let question: String

    var body: some View {
        LaTeXView(content: question)
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
    }
}

struct AnswerSection: View {
    let answer: String
    let explanation: String
    let choices: [AnswerChoice]
    @Binding var selectedChoiceID: Int?
    let isVisible: Bool
    let onSelect: (Int) -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            MultipleChoiceCard(
                choices: choices,
                selectedChoiceID: selectedChoiceID,
                onSelect: onSelect
            )

            Button(action: onToggle) {
                Label(
                    isVisible ? "Hide Solution" : "View Solution",
                    systemImage: isVisible ? "eye.slash.fill" : "eye.fill"
                )
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(.indigo)

            if isVisible {
                AnswerCard(answer: answer, explanation: explanation)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct MultipleChoiceCard: View {
    let choices: [AnswerChoice]
    let selectedChoiceID: Int?
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Choose One Answer", systemImage: "list.bullet.circle")
                .font(.headline)
                .foregroundStyle(.indigo)

            ForEach(choices) { choice in
                MultipleChoiceRow(
                    choice: choice,
                    isSelected: selectedChoiceID == choice.id,
                    hasSelection: selectedChoiceID != nil,
                    onSelect: { onSelect(choice.id) }
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.indigo.opacity(0.2), lineWidth: 1)
        }
    }
}

struct MultipleChoiceRow: View {
    let choice: AnswerChoice
    let isSelected: Bool
    let hasSelection: Bool
    let onSelect: () -> Void

    private var borderColor: Color {
        guard hasSelection else { return .white.opacity(0.18) }
        if choice.isCorrect { return .green }
        return isSelected ? .red : .white.opacity(0.12)
    }

    private var iconName: String {
        guard hasSelection else { return "circle" }
        if choice.isCorrect { return "checkmark.circle.fill" }
        return isSelected ? "xmark.circle.fill" : "circle"
    }

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundStyle(choice.isCorrect && hasSelection ? .green : (isSelected ? .red : .secondary))

                LaTeXView(content: choice.text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .allowsHitTesting(false)
            }
            .padding(14)
            .contentShape(Rectangle())
            .background(Color.white.opacity(isSelected ? 0.10 : 0.045), in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(borderColor, lineWidth: isSelected || (choice.isCorrect && hasSelection) ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(hasSelection)
        .accessibilityLabel("Answer choice")
    }
}

struct AnswerCard: View {
    let answer: String
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Answer", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.green)

            LaTeXView(content: answer)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))

            Divider()

            Text("Detailed Solution")
                .font(.headline)

            LaTeXView(content: explanation)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.green.opacity(0.25), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SourceAttributionView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Source: Calculus 1,000 Advanced Problems with Detailed Solutions")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Each problem includes a complete derivation")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 8)
    }
}

struct RandomQuestionButton: View {
    let hasQuestion: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(
                hasQuestion ? "Draw Another" : "Random Problem",
                systemImage: "dice.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(.indigo)
        .shadow(color: Color.indigo.opacity(0.25), radius: 10, y: 5)
    }
}

extension CalculusQuestion {
    static let samples: [CalculusQuestion] = [
        q(1, .limitsAndContinuity, .easy,
          "Evaluate lim x→2  (x² − 4) / (x − 2).",
          "4",
          "將分子分解為 (x − 2)(x + 2)，約分後代入 x = 2，得到 4。"),
        q(2, .limitsAndContinuity, .medium,
          "Evaluate lim x→0  sin(x) / x.",
          "1",
          "這是基本三角極限。x 以弧度表示並趨近 0 時，sin(x) / x 趨近 1。"),
        q(3, .limitsAndContinuity, .hard,
          "Let f(x) = kx for x < 2 and f(x) = x² for x ≥ 2. Find k so that f is continuous at x = 2.",
          "k = 2",
          "連續要求左右極限與函數值相等，因此 2k = 2² = 4，解得 k = 2。"),

        q(4, .derivatives, .easy,
          "Find f′(x) if f(x) = x² + 3x − 5.",
          "f′(x) = 2x + 3",
          "使用冪次法則逐項微分：x² 變成 2x、3x 變成 3、常數項變成 0。"),
        q(5, .derivatives, .medium,
          "Find f′(x) if f(x) = (x² + 1)³.",
          "f′(x) = 6x(x² + 1)²",
          "使用鏈鎖律：外層導數為 3(x² + 1)²，再乘內層導數 2x。"),
        q(6, .derivatives, .hard,
          "Find f′(x) if f(x) = xeˣ.",
          "f′(x) = eˣ(x + 1)",
          "使用乘法法則得到 eˣ + xeˣ，再提出公因式 eˣ。"),

        q(7, .derivativeApplications, .easy,
          "Find the equation of the tangent line to y = x² at x = 1.",
          "y = 2x − 1",
          "導數為 2x，所以切線斜率是 2；切點為 (1, 1)。代入點斜式 y − 1 = 2(x − 1)。"),
        q(8, .derivativeApplications, .medium,
          "Find the local maximum and local minimum values of f(x) = x³ − 3x.",
          "局部極大值 2；局部極小值 −2",
          "令 f′(x) = 3x² − 3 = 0，得 x = ±1。由二階導數 6x 判斷：x = −1 為極大，x = 1 為極小。"),
        q(9, .derivativeApplications, .hard,
          "The radius of a circle increases at 2 cm/s. How fast is its area increasing when the radius is 3 cm?",
          "12π 平方公分／秒",
          "A = πr²，對時間微分得 dA/dt = 2πr · dr/dt。代入 r = 3、dr/dt = 2，得到 12π。"),

        q(10, .basicIntegrals, .easy,
          "Evaluate ∫ (2x + 3) dx.",
          "x² + 3x + C",
          "逐項積分：∫2x dx = x²、∫3 dx = 3x，最後加積分常數 C。"),
        q(11, .basicIntegrals, .medium,
          "Evaluate the definite integral ∫₀² x² dx.",
          "8/3",
          "x² 的反導函數為 x³/3。代入上下限得到 2³/3 − 0³/3 = 8/3。"),
        q(12, .basicIntegrals, .hard,
          "Let F(x) = ∫₀ˣ cos(t²) dt. Find F′(x).",
          "F′(x) = cos(x²)",
          "依微積分基本定理，積分上限為 x 時，導數就是被積函數將 t 換成 x。"),

        q(13, .integrationTechniques, .easy,
          "Evaluate ∫ 2x cos(x²) dx.",
          "sin(x²) + C",
          "令 u = x²，則 du = 2x dx。原式變成 ∫cos(u) du = sin(u) + C。"),
        q(14, .integrationTechniques, .medium,
          "Evaluate ∫ x ln(x) dx.",
          "(x²/2)ln(x) − x²/4 + C",
          "使用分部積分，令 u = ln(x)、dv = x dx，則 du = dx/x、v = x²/2。"),
        q(15, .integrationTechniques, .hard,
          "Evaluate ∫ 1/(x² − 1) dx.",
          "½ ln|(x − 1)/(x + 1)| + C",
          "部分分式分解為 ½/(x − 1) − ½/(x + 1)，分別積分後合併對數。"),

        q(16, .integralApplications, .easy,
          "Find the area enclosed by y = x and y = x² on 0 ≤ x ≤ 1.",
          "1/6",
          "區間內 x 位於 x² 上方。計算 ∫₀¹(x − x²)dx = [x²/2 − x³/3]₀¹ = 1/6。"),
        q(17, .integralApplications, .medium,
          "Rotate the region under y = √x on 0 ≤ x ≤ 4 about the x-axis. Find the volume.",
          "8π",
          "使用圓盤法：V = π∫₀⁴(√x)²dx = π∫₀⁴x dx = 8π。"),
        q(18, .integralApplications, .hard,
          "Find the arc length of y = (2/3)x^(3/2) on 0 ≤ x ≤ 1.",
          "(2/3)(2√2 − 1)",
          "y′ = √x。弧長為 ∫₀¹√(1 + x)dx = [(2/3)(1 + x)^(3/2)]₀¹。"),

        q(19, .differentialEquations, .easy,
          "Solve the differential equation dy/dx = 3x².",
          "y = x³ + C",
          "兩側對 x 積分：y = ∫3x²dx = x³ + C。"),
        q(20, .differentialEquations, .medium,
          "Solve the initial-value problem y′ = 2y, y(0) = 3.",
          "y = 3e²ˣ",
          "分離變數得 dy/y = 2dx，積分後 y = Ce²ˣ。由 y(0) = 3 得 C = 3。"),
        q(21, .differentialEquations, .hard,
          "Solve the initial-value problem y′ = y(1 − y), y(0) = 1/2.",
          "y = 1/(1 + e⁻ˣ)",
          "分離變數並以部分分式積分，得到 ln(y/(1 − y)) = x + C。初值給出 C = 0。"),

        q(22, .sequencesAndSeries, .easy,
          "Determine whether aₙ = 1/n converges and find its limit.",
          "收斂到 0",
          "當 n 趨近無限大時，分母無限增大，因此 1/n 趨近 0。"),
        q(23, .sequencesAndSeries, .medium,
          "Find the sum of the infinite series Σₙ₌₀∞ (1/2)ⁿ.",
          "2",
          "這是首項 1、公比 1/2 的等比級數。和為 1/(1 − 1/2) = 2。"),
        q(24, .sequencesAndSeries, .hard,
          "Write the Maclaurin series for eˣ.",
          "Σₙ₌₀∞ xⁿ/n! = 1 + x + x²/2! + x³/3! + ⋯",
          "eˣ 的每階導數仍為 eˣ，在 0 的值皆為 1；代入 Taylor 級數公式即可。"),

        q(25, .parametricAndPolar, .easy,
          "For x = t² and y = t³, find dy/dx.",
          "dy/dx = 3t/2",
          "dy/dx = (dy/dt)/(dx/dt) = 3t²/(2t) = 3t/2，t ≠ 0。"),
        q(26, .parametricAndPolar, .medium,
          "Find the arc length of x = cos(t), y = sin(t), 0 ≤ t ≤ 2π.",
          "2π",
          "速度為 √((-sin t)² + (cos t)²) = 1，因此弧長是 ∫₀²π1dt = 2π。"),
        q(27, .parametricAndPolar, .hard,
          "Find the area enclosed by r = 2cos(θ), −π/2 ≤ θ ≤ π/2.",
          "π",
          "極座標面積為 ½∫r²dθ = 2∫₋π/2^π/2 cos²θ dθ = π。"),

        q(28, .multivariable, .easy,
          "For f(x,y) = x²y + sin(y), find fₓ and fᵧ.",
          "fₓ = 2xy；fᵧ = x² + cos(y)",
          "求 fₓ 時將 y 視為常數；求 fᵧ 時將 x 視為常數，分別逐項微分。"),
        q(29, .multivariable, .medium,
          "Find ∇f(1, −2) for f(x,y) = x² + y².",
          "∇f(1, −2) = (2, −4)",
          "∇f = (fₓ, fᵧ) = (2x, 2y)。代入 (1, −2) 得 (2, −4)。"),
        q(30, .multivariable, .hard,
          "For f(x,y) = xy, find the directional derivative at (1,2) in the direction of (3,4).",
          "2",
          "單位方向向量為 (3/5, 4/5)，而 ∇f(1,2) = (2,1)。點積為 6/5 + 4/5 = 2。"),

        q(31, .multipleAndVector, .easy,
          "Evaluate ∬ᴿ (x + y)dA, where R = [0,1] × [0,1].",
          "1",
          "先對 y、再對 x 積分；或利用對稱性。兩部分的積分各為 1/2，總和為 1。"),
        q(32, .multipleAndVector, .medium,
          "Use a triple integral to find the volume of the unit sphere.",
          "4π/3",
          "使用球座標，體積元素為 ρ²sinφ dρ dφ dθ。三個範圍積分後得到 4π/3。"),
        q(33, .multipleAndVector, .hard,
          "Evaluate ∮ F · dr counterclockwise around the unit circle for F(x,y) = (2x, 2y).",
          "0",
          "F = ∇(x² + y²) 是保守場。保守場沿任意封閉曲線的線積分為 0。"),
        q(34, .limitsAndContinuity, .hard,
          "Evaluate lim x→0  (eˣ − 1 − x) / x².",
          "1/2",
          "Apply L’Hôpital’s rule twice, or use eˣ = 1 + x + x²/2 + ⋯. The remaining leading term is x²/2."),
        q(35, .limitsAndContinuity, .hard,
          "Using the ε–δ definition, find a valid δ in terms of ε for lim x→2 3x = 6.",
          "δ = ε/3",
          "We need |3x − 6| = 3|x − 2| < ε. Choosing δ = ε/3 guarantees the inequality."),

        q(36, .derivatives, .hard,
          "The curve x² + xy + y² = 7 defines y implicitly. Find dy/dx.",
          "dy/dx = −(2x + y)/(x + 2y)",
          "Differentiate implicitly: 2x + x(dy/dx) + y + 2y(dy/dx) = 0, then solve for dy/dx."),
        q(37, .derivatives, .hard,
          "Find the nth derivative of f(x) = x²eˣ.",
          "f⁽ⁿ⁾(x) = eˣ[x² + 2nx + n(n − 1)]",
          "Apply Leibniz’s rule. Derivatives of x² vanish after order two, leaving three terms."),

        q(38, .derivativeApplications, .hard,
          "A closed cylinder has fixed volume V. Determine the relation between height h and radius r that minimizes its surface area.",
          "h = 2r",
          "Use V = πr²h to eliminate h from S = 2πr² + 2πrh, differentiate with respect to r, and set S′ = 0."),
        q(39, .derivativeApplications, .hard,
          "Use one Newton iteration for x³ − x − 1 = 0 starting from x₀ = 1.5. Find x₁.",
          "x₁ = 1.347826…",
          "Newton’s formula gives x₁ = 1.5 − (1.5³ − 1.5 − 1)/(3(1.5)² − 1) = 1.347826…"),

        q(40, .basicIntegrals, .hard,
          "Determine whether ∫₁∞ 1/x² dx converges, and find its value.",
          "It converges to 1.",
          "Evaluate lim b→∞ [−1/x]₁ᵇ = lim b→∞ (1 − 1/b) = 1."),
        q(41, .basicIntegrals, .hard,
          "Find the average value of f(x) = ln(x) on [1, e].",
          "1/(e − 1)",
          "The average value is (1/(e−1))∫₁ᵉ ln(x)dx. The integral equals 1."),

        q(42, .integrationTechniques, .hard,
          "Evaluate ∫ sec³(x) dx.",
          "½[sec(x)tan(x) + ln|sec(x) + tan(x)|] + C",
          "Use integration by parts, then isolate the original integral after applying tan²(x) = sec²(x) − 1."),
        q(43, .integrationTechniques, .hard,
          "Evaluate ∫ √(9 − x²) dx.",
          "(x/2)√(9 − x²) + (9/2)arcsin(x/3) + C",
          "Use x = 3sin(θ), convert the integral to 9∫cos²(θ)dθ, and substitute back."),

        q(44, .integralApplications, .hard,
          "Rotate the region between y = 4 and y = x² for 0 ≤ x ≤ 2 about the y-axis. Find the volume using cylindrical shells.",
          "8π",
          "V = 2π∫₀² x(4 − x²)dx = 2π[2x² − x⁴/4]₀² = 8π."),
        q(45, .integralApplications, .hard,
          "Find the centroid’s x-coordinate for the region under y = 2x on 0 ≤ x ≤ 1.",
          "x̄ = 2/3",
          "The area is 1. The moment about the y-axis is ∫₀¹ x(2x)dx = 2/3, so x̄ = 2/3."),

        q(46, .differentialEquations, .hard,
          "Solve y″ − 3y′ + 2y = 0.",
          "y = C₁eˣ + C₂e²ˣ",
          "The characteristic equation r² − 3r + 2 = 0 has roots r = 1 and r = 2."),
        q(47, .differentialEquations, .hard,
          "Use Euler’s method with h = 0.1 to approximate y(0.2) for y′ = x + y, y(0) = 1.",
          "y(0.2) ≈ 1.22",
          "Euler steps give y₁ = 1 + 0.1(1) = 1.1 and y₂ = 1.1 + 0.1(0.1 + 1.1) = 1.22."),

        q(48, .sequencesAndSeries, .hard,
          "Find the interval of convergence of Σₙ₌₁∞ xⁿ/n.",
          "[−1, 1)",
          "The radius is 1. At x = 1 the harmonic series diverges; at x = −1 the alternating harmonic series converges."),
        q(49, .sequencesAndSeries, .hard,
          "Determine whether Σₙ₌₁∞ (3n + 1)/(n³ + 2) converges.",
          "It converges.",
          "Limit comparison with 1/n² gives a finite positive limit of 3, so both series converge."),

        q(50, .parametricAndPolar, .hard,
          "Find the curvature of r(t) = (t, t²) at t = 0.",
          "κ = 2",
          "For a plane curve, κ = |x′y″ − y′x″|/(x′² + y′²)^(3/2). Substitution at t = 0 gives 2."),
        q(51, .parametricAndPolar, .hard,
          "For the polar curve r = 1 + cos(θ), find dy/dx at θ = π/2.",
          "dy/dx = 1",
          "Use dx/dθ = r′cosθ − r sinθ and dy/dθ = r′sinθ + r cosθ. Both equal −1 at θ = π/2."),

        q(52, .multivariable, .hard,
          "Find the tangent plane to z = x² + xy + y² at (1, 1, 3).",
          "z = 3x + 3y − 3",
          "At (1,1), fₓ = 2x + y = 3 and fᵧ = x + 2y = 3. Apply the tangent-plane formula."),
        q(53, .multivariable, .hard,
          "Find the maximum and minimum of f(x,y) = xy subject to x² + y² = 1.",
          "Maximum 1/2; minimum −1/2",
          "Lagrange multipliers give y = 2λx and x = 2λy. The extrema occur when |x| = |y| = 1/√2."),

        q(54, .multipleAndVector, .hard,
          "Reverse the order of integration for ∫₀¹∫ₓ¹ f(x,y) dy dx.",
          "∫₀¹∫₀ʸ f(x,y) dx dy",
          "The region is 0 ≤ x ≤ y ≤ 1. With y outermost, 0 ≤ y ≤ 1 and 0 ≤ x ≤ y."),
        q(55, .multipleAndVector, .hard,
          "Use the Divergence Theorem to find the outward flux of F = (x,y,z) across the sphere x² + y² + z² = 4.",
          "32π",
          "div F = 3. Multiply by the volume of the radius-2 ball: 3 · (4π/3) · 2³ = 32π."),
        q(56, .limitsAndContinuity, .hard,
          "Evaluate lim x→0 (tan(x) − x) / x³.",
          "1/3",
          "Use the Taylor expansion tan(x) = x + x³/3 + O(x⁵), or apply L’Hôpital’s rule three times."),
        q(57, .limitsAndContinuity, .hard,
          "Evaluate lim n→∞ n(√(n² + 1) − n).",
          "1/2",
          "Rationalize the difference to obtain n/(√(n² + 1) + n), then divide numerator and denominator by n."),
        q(58, .limitsAndContinuity, .hard,
          "Prove or evaluate lim x→0 (1 + x)^(1/x).",
          "e",
          "Take logarithms. The logarithm of the limit is lim x→0 ln(1+x)/x = 1, so the original limit is e."),

        q(59, .derivatives, .hard,
          "Let f(x) = x + x³ and let g = f⁻¹. Find g″(2).",
          "−3/32",
          "Since f(1) = 2, use g″(y) = −f″(x)/(f′(x))³ at x = 1: −6/4³ = −3/32."),
        q(60, .derivatives, .hard,
          "Differentiate y = xˣ for x > 0.",
          "y′ = xˣ(ln(x) + 1)",
          "Take logarithms: ln y = x ln x. Differentiate implicitly and multiply by y."),
        q(61, .derivatives, .hard,
          "For x² + y² = 25, find d²y/dx² at (3,4).",
          "−25/64",
          "First y′ = −x/y. Differentiating again gives y″ = −(y² + x²)/y³ = −25/y³."),

        q(62, .derivativeApplications, .hard,
          "Find the minimum distance from the point (0,3) to the parabola y = x².",
          "√11 / 2",
          "Minimize D² = x² + (x² − 3)². Critical points occur at x = 0 and x² = 5/2; the latter gives the minimum."),
        q(63, .derivativeApplications, .hard,
          "A rectangle is symmetric about the y-axis, lies above the x-axis, and has its upper corners on y = 12 − x². Find its maximum area.",
          "32",
          "If the upper-right corner is (x,12−x²), then A = 2x(12−x²). Solve A′ = 24−6x² = 0."),
        q(64, .derivativeApplications, .hard,
          "Apply the Mean Value Theorem to f(x) = ln(x) on [1,e]. Find every valid c.",
          "c = e − 1",
          "Set f′(c) = 1/c equal to the secant slope (ln e − ln 1)/(e − 1) = 1/(e−1)."),

        q(65, .basicIntegrals, .hard,
          "Evaluate the improper integral ∫₀∞ x e^(−x²) dx.",
          "1/2",
          "Let u = x². The integral becomes ½∫₀∞e^(−u)du = 1/2."),
        q(66, .basicIntegrals, .hard,
          "Evaluate the improper integral ∫₀¹ ln(x) dx.",
          "−1",
          "Use x ln x − x as an antiderivative and the limit lim x→0⁺ x ln x = 0."),
        q(67, .basicIntegrals, .hard,
          "Differentiate F(x) = ∫ₓ²^sin(x) e^(t²) dt.",
          "F′(x) = e^(sin²x)cos(x) − 2x e^(x⁴)",
          "Apply the Fundamental Theorem of Calculus to both variable limits, including their chain-rule factors."),

        q(68, .integrationTechniques, .hard,
          "Evaluate ∫ x³/(x² + 1) dx.",
          "x²/2 − ½ln(x² + 1) + C",
          "Divide x³ by x²+1 to get x − x/(x²+1), then integrate."),
        q(69, .integrationTechniques, .hard,
          "Evaluate ∫ sin³(x)cos²(x) dx.",
          "−cos³(x)/3 + cos⁵(x)/5 + C",
          "Write sin³x = sin x(1−cos²x), then substitute u = cos x."),
        q(70, .integrationTechniques, .hard,
          "Evaluate ∫ dx/(x² + 4x + 13).",
          "(1/3)arctan((x + 2)/3) + C",
          "Complete the square: x²+4x+13 = (x+2)²+9, then use the arctangent formula."),

        q(71, .integralApplications, .hard,
          "Find the area of one petal of the polar rose r = cos(3θ).",
          "π/12",
          "One petal is traced for −π/6 ≤ θ ≤ π/6. Compute ½∫cos²(3θ)dθ over that interval."),
        q(72, .integralApplications, .hard,
          "Rotate y = √(4 − x²), −2 ≤ x ≤ 2, about the x-axis. Find the surface area.",
          "16π",
          "The rotation forms a sphere of radius 2. The surface-area integral also evaluates to 4πr² = 16π."),
        q(73, .integralApplications, .hard,
          "A spring obeys Hooke’s law with k = 40 N/m. Find the work required to stretch it from 0.1 m to 0.3 m.",
          "1.6 J",
          "Compute ∫₀.₁⁰.³ 40x dx = 20(0.3² − 0.1²) = 1.6."),

        q(74, .differentialEquations, .hard,
          "Solve the linear differential equation y′ + 2y = e^(−x).",
          "y = e^(−x) + Ce^(−2x)",
          "Use integrating factor e²ˣ. Then (e²ˣy)′ = eˣ and integrate."),
        q(75, .differentialEquations, .hard,
          "Find the general solution of y″ + 4y = cos(2x).",
          "y = C₁cos(2x) + C₂sin(2x) + (x/4)sin(2x)",
          "The forcing frequency is resonant with the homogeneous solution, so multiply the usual trial function by x."),
        q(76, .differentialEquations, .hard,
          "Solve y′ = y² with y(0) = −1, and state its maximal interval containing 0.",
          "y = −1/(x + 1), on (−1, ∞)",
          "Separate variables to obtain −1/y = x + C. The initial value gives C = 1; the solution is singular at x = −1."),

        q(77, .sequencesAndSeries, .hard,
          "Evaluate Σₙ₌₁∞ n/2ⁿ.",
          "2",
          "Differentiate the geometric series Σxⁿ = 1/(1−x), multiply by x, and set x = 1/2."),
        q(78, .sequencesAndSeries, .hard,
          "Find the radius of convergence of Σₙ₌₀∞ n! xⁿ.",
          "R = 0",
          "The ratio of successive absolute terms is (n+1)|x|, which diverges for every x ≠ 0."),
        q(79, .sequencesAndSeries, .hard,
          "Using five terms of the alternating harmonic series to approximate ln(2), give a guaranteed error bound.",
          "Error ≤ 1/6",
          "The Alternating Series Estimation Theorem bounds the error by the magnitude of the first omitted term."),

        q(80, .parametricAndPolar, .hard,
          "Find the area inside r = 2sin(θ) but outside r = 1.",
          "π/3 + √3/2",
          "The curves meet at θ = π/6 and 5π/6. Integrate ½[(2sinθ)²−1] between these angles."),
        q(81, .parametricAndPolar, .hard,
          "For x = t − ln(t), y = t + 1/t with t > 0, find the tangent line at t = 1.",
          "y − 2 = 2(x − 1)",
          "Although both derivatives vanish at t = 1, simplify (dy/dt)/(dx/dt) = (t+1)/t for t ≠ 1 and take the limit 2."),
        q(82, .parametricAndPolar, .hard,
          "Find the total arc length of the polar curve r = 2sin(θ), 0 ≤ θ ≤ π.",
          "2π",
          "The curve is a circle of radius 1. Directly, √(r²+(dr/dθ)²) = 2, whose integral from 0 to π is 2π."),

        q(83, .multivariable, .hard,
          "Find and classify all critical points of f(x,y) = x³ + y³ − 3xy.",
          "(0,0) is a saddle; (1,1) is a local minimum.",
          "Solve x²=y and y²=x. Then apply the Hessian test using D = 36xy−9."),
        q(84, .multivariable, .hard,
          "Let z = x²y, x = r cos(θ), and y = r sin(θ). Find ∂z/∂r.",
          "∂z/∂r = 3r²cos²(θ)sin(θ)",
          "Substitute first to get z = r³cos²θ sinθ, then differentiate with respect to r."),
        q(85, .multivariable, .hard,
          "Find the maximum and minimum of x + y + z on the unit sphere x² + y² + z² = 1.",
          "Maximum √3; minimum −√3",
          "Use Lagrange multipliers or Cauchy–Schwarz. Equality occurs in the directions ±(1,1,1)/√3."),

        q(86, .multipleAndVector, .hard,
          "Evaluate ∭ᴮ (x² + y²)dV over the unit ball B.",
          "8π/15",
          "By symmetry, the integral is two-thirds of ∭ᴮr²dV. In spherical coordinates this is (2/3)4π∫₀¹r⁴dr."),
        q(87, .multipleAndVector, .hard,
          "Compute curl F and determine whether F = (yz, xz, xy) is conservative on ℝ³.",
          "curl F = 0; F is conservative with potential xyz.",
          "All three components of the curl cancel. Since ℝ³ is simply connected, F is conservative."),
        q(88, .multipleAndVector, .hard,
          "Use Stokes’ Theorem to evaluate ∮ᶜ (−y, x, 0) · dr, where C is the unit circle oriented counterclockwise.",
          "2π",
          "curl F = (0,0,2). Its flux through the unit disk is 2 times the disk area, hence 2π.")
    ]

    static let questionBank: [CalculusQuestion] = {
        let detailedQuestions = DetailedQuestionBank.load()
        return detailedQuestions.isEmpty ? samples : detailedQuestions
    }()

    private static func q(
        _ id: Int,
        _ category: CalculusCategory,
        _ difficulty: QuestionDifficulty,
        _ question: String,
        _ answer: String,
        _ explanation: String
    ) -> CalculusQuestion {
        CalculusQuestion(
            id: id,
            category: category,
            difficulty: difficulty,
            question: question,
            answer: answer,
            explanation: explanation
        )
    }
}

enum AdvancedQuestionFactory {
    static func makeQuestions(startingAt firstID: Int, count: Int) -> [CalculusQuestion] {
        (0..<count).map { offset in
            makeQuestion(
                id: firstID + offset,
                variant: offset / 18,
                template: offset % 18
            )
        }
    }

    private static func makeQuestion(
        id: Int,
        variant: Int,
        template: Int
    ) -> CalculusQuestion {
        let a = variant + 2
        let b = variant % 7 + 2
        let c = variant % 5 + 3

        switch template {
        case 0:
            return question(
                id, .limitsAndContinuity,
                "Without directly quoting a Taylor polynomial, evaluate\nlim x→0 [e^(\(a)x) − 1 − \(a)x] / x².",
                "\(a * a)/2",
                "Apply L’Hôpital’s rule twice. The second derivatives of the numerator and denominator at zero are \(a * a) and 2."
            )
        case 1:
            return question(
                id, .limitsAndContinuity,
                "Evaluate the third-order cancellation limit\nlim x→0 [sin(\(a)x) − \(a)x] / x³.",
                "−\(a * a * a)/6",
                "Use the cubic term of sin(u), or apply L’Hôpital’s rule three times."
            )
        case 2:
            return question(
                id, .limitsAndContinuity,
                "Evaluate\nlim m→∞ m[√(m² + \(a)) − m]\nby rationalization.",
                "\(a)/2",
                "After rationalizing, the expression is \(a)m/[√(m²+\(a))+m]. Divide through by m."
            )
        case 3:
            let denominator = 1 + 3 * a
            return question(
                id, .derivatives,
                "Let f(x) = x + \(a)x³ and g = f⁻¹. Compute g″(\(a + 1)).",
                "−\(6 * a)/(\(denominator)³)",
                "Since f(1)=\(a + 1), use g″(f(x)) = −f″(x)/(f′(x))³ at x=1."
            )
        case 4:
            return question(
                id, .derivatives,
                "Differentiate the logarithmic-power function\nf(x) = x^\(a) ln(x),  x > 0.",
                "f′(x) = x^(\(a - 1))[\(a)ln(x) + 1]",
                "Apply the product rule to x^\(a) and ln(x), then factor x^(\(a - 1))."
            )
        case 5:
            return question(
                id, .derivatives,
                "For the implicit curve\n\(a)x² + xy + \(b)y² = \(a + b + 1),\nfind dy/dx at (1,1).",
                "dy/dx = −\(2 * a + 1)/\(2 * b + 1)",
                "Differentiate implicitly and solve (x+2\(b)y)y′ = −(2\(a)x+y), then substitute (1,1)."
            )
        case 6:
            return question(
                id, .derivativeApplications,
                "Find the global maximum of\nf(x) = x^\(a)(1 − x) on [0,1],\nand state where it occurs.",
                "Maximum \(a)^\(a)/(\(a + 1)^\(a + 1)) at x = \(a)/\(a + 1)",
                "Logarithmic differentiation or the product rule gives the interior critical point x=\(a)/(\(a)+1). Compare endpoints."
            )
        case 7:
            return question(
                id, .basicIntegrals,
                "Evaluate the improper Gamma-type integral\n∫₀∞ x^\(b)e^(−\(a)x) dx.",
                "\(b)! / \(a)^(\(b + 1))",
                "Substitute u=\(a)x and use Γ(\(b + 1))=\(b)!."
            )
        case 8:
            return question(
                id, .integrationTechniques,
                "Evaluate\n∫ x³/(x² + \(a * a)) dx.",
                "x²/2 − \(a * a)/2 ln(x² + \(a * a)) + C",
                "Rewrite x³/(x²+\(a * a)) as x − \(a * a)x/(x²+\(a * a))."
            )
        case 9:
            return question(
                id, .differentialEquations,
                "Solve the nonhomogeneous equation\ny′ + \(a)y = e^(−x).",
                "y = e^(−x)/(\(a - 1)) + Ce^(−\(a)x)",
                "Use the integrating factor e^(\(a)x). The assumption \(a)≥2 avoids resonance."
            )
        case 10:
            return question(
                id, .sequencesAndSeries,
                "Evaluate the weighted geometric series\nΣ n/\(a)^n,  n = 1…∞.",
                "\(a)/(\(a - 1)²)",
                "Differentiate the geometric series and substitute r=1/\(a): Σnrⁿ=r/(1−r)²."
            )
        case 11:
            return question(
                id, .sequencesAndSeries,
                "Find the radius and interval of convergence of\nΣ n^\(b)xⁿ,  n = 1…∞.",
                "R = 1; interval (−1,1)",
                "The root test gives radius 1. At both endpoints the terms fail to approach zero."
            )
        case 12:
            return question(
                id, .parametricAndPolar,
                "Find the exact area of one petal of the polar rose\nr = \(a)cos(\(b)θ).",
                "\(a * a)π/\(4 * b)",
                "Integrate ½r² from −π/(2\(b)) to π/(2\(b))."
            )
        case 13:
            return question(
                id, .parametricAndPolar,
                "For r(t) = (t, \(a)t²), compute the curvature κ at t = \(b).",
                "κ = \(2 * a)/[1 + \(4 * a * a * b * b)]^(3/2)",
                "Use κ=|x′y″−y′x″|/(x′²+y′²)^(3/2)."
            )
        case 14:
            let z = a + b + c
            let fx = 2 * a + b
            let fy = b + 2 * c
            return question(
                id, .multivariable,
                "Find the tangent plane at (1,1,\(z)) to\nz = \(a)x² + \(b)xy + \(c)y².",
                "z − \(z) = \(fx)(x − 1) + \(fy)(y − 1)",
                "Compute fₓ=2\(a)x+\(b)y and fᵧ=\(b)x+2\(c)y, then evaluate at (1,1)."
            )
        case 15:
            return question(
                id, .multivariable,
                "Find the absolute extrema of\nL(x,y,z) = \(a)x + \(b)y + \(c)z\non the sphere x²+y²+z² = \(a * a).",
                "Maximum \(a)√(\(a * a + b * b + c * c)); minimum is its negative",
                "Use Cauchy–Schwarz or Lagrange multipliers. Equality occurs parallel or antiparallel to (\(a),\(b),\(c))."
            )
        case 16:
            return question(
                id, .multipleAndVector,
                "Evaluate\n∫₀^\(a)∫₀^\(b) [\(c)x + \(a)y] dy dx.",
                "\(c * a * a * b)/2 + \(a * a * b * b)/2",
                "Integrate each linear term over the rectangle; equivalently use the centroid (\(a)/2,\(b)/2) times its area."
            )
        default:
            let divergence = a + b + c
            return question(
                id, .multipleAndVector,
                "Use the Divergence Theorem to find the outward flux of\nF=(\(a)x, \(b)y, \(c)z)\nacross the sphere x²+y²+z²=\(b * b).",
                "4π(\(b)³)(\(divergence))/3",
                "The divergence is \(divergence). Multiply it by the volume 4π\(b)³/3."
            )
        }
    }

    private static func question(
        _ id: Int,
        _ category: CalculusCategory,
        _ prompt: String,
        _ answer: String,
        _ explanation: String
    ) -> CalculusQuestion {
        CalculusQuestion(
            id: id,
            category: category,
            difficulty: .hard,
            question: prompt,
            answer: answer,
            explanation: explanation
        )
    }
}

#Preview {
    ContentView()
}
