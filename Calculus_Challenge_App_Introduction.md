# Calculus Challenge — 隨機微積分挑戰 App

## 作品介紹

Calculus Challenge 是一款使用 SwiftUI 製作的隨機微積分選擇題 App。App 收錄 1,000 道英文進階微積分題目，範圍包含極限、微分、積分、微分方程、級數、多變數微積分與向量微積分。

使用者從大廳按下 **Start Random Challenge** 後，App 會隨機抽出一道題目。每題提供四個選項，作答後會顯示正確答案與詳細解法。所有題目與公式資源皆存放在 App 內，不需要網路即可使用。

## 作業要求對照

1. **點選隨機按鈕後呈現答案**：按下開始或 Draw Another 後，使用 `randomElement()` 抽題。
2. **定義資料型別**：使用 `CalculusQuestion` 與 `AnswerChoice` 儲存題目和選項。
3. **至少五筆資料並存入 Array**：題庫型別為 `[CalculusQuestion]`，共 1,000 題。
4. **至少顯示三種資訊**：畫面會顯示題型、難度、題目、選項、答案與詳細解法。
5. **圖文呈現**：使用 SF Symbols 圖示、文字及 LaTeX 數學公式呈現內容。

## 資料型別

每一道題目包含編號、分類、難度、題目、答案與詳細解答。

```swift
struct CalculusQuestion: Identifiable, Equatable {
    let id: Int
    let category: CalculusCategory
    let difficulty: QuestionDifficulty
    let question: String
    let answer: String
    let explanation: String
}
```

每個選項則包含選項編號、顯示內容，以及是否為正確答案。

```swift
struct AnswerChoice: Identifiable, Equatable {
    let id: Int
    let text: String
    let isCorrect: Bool
}
```

利用明確的資料型別，可讓畫面直接讀取題目資訊，也能安全地判斷答案。

## 使用 Array 儲存題庫

題庫使用 `[CalculusQuestion]` Array。App 優先載入內建的 1,000 題詳細題庫；若題庫檔案無法讀取，則使用程式內的備用題目。

```swift
static let questionBank: [CalculusQuestion] = {
    let detailedQuestions = DetailedQuestionBank.load()
    return detailedQuestions.isEmpty ? samples : detailedQuestions
}()
```

載入題庫時，逐題解析資料並加入 Array。

```swift
var questions: [CalculusQuestion] = []

for section in markdown.components(separatedBy: "\n### Question ").dropFirst() {
    if let question = parseQuestion(section) {
        questions.append(question)
    }
}

return questions.sorted { $0.id < $1.id }
```

## 隨機抽題功能

按下按鈕後，先排除目前顯示的題目，再從剩餘題目中隨機選出下一題，因此不會連續抽到同一題。

```swift
private func selectRandomQuestion() {
    let availableQuestions = questions.filter {
        $0.id != currentQuestion?.id
    }

    guard let nextQuestion = availableQuestions.randomElement() else {
        return
    }

    isAnswerVisible = false
    selectedChoiceID = nil
    currentQuestion = nextQuestion
}
```

大廳的開始按鈕會先抽題，再進入答題畫面。

```swift
LobbyView {
    selectRandomQuestion()
    withAnimation(.easeInOut(duration: 0.3)) {
        isShowingLobby = false
    }
}
```

## 四選一作答功能

選項使用 `ForEach` 顯示。每個選項框都是一個 Button，因此點擊框內任意位置都可以作答。

```swift
ForEach(choices) { choice in
    MultipleChoiceRow(
        choice: choice,
        isSelected: selectedChoiceID == choice.id,
        hasSelection: selectedChoiceID != nil,
        onSelect: { onSelect(choice.id) }
    )
}
```

使用者作答後，App 會記錄所選選項並顯示答案。

```swift
private func selectChoice(_ choiceID: Int) {
    withAnimation(.easeInOut(duration: 0.25)) {
        selectedChoiceID = choiceID
        isAnswerVisible = true
    }
}
```

正確選項顯示綠色，錯誤選項顯示紅色，讓使用者立即知道作答結果。

## 自動產生四個選項

每題以正確答案為基礎產生三個不同的干擾選項，並依題目編號改變正確答案所在位置，避免所有題目的答案都在相同位置。

```swift
let proposedDistractors = [
    swappedOperators(in: expression),
    omittedChainFactor(in: expression),
    changedCoefficient(in: expression)
]

let correctPosition = id % 4
var ordered = Array(candidates.dropFirst().prefix(3))
ordered.insert(expression, at: correctPosition)
```

## LaTeX 數學公式

題目、選項、答案與詳細解法都透過 `LaTeXView` 顯示。公式使用 App 內建的 MathJax 檔案轉換，不需要連接網路。

```swift
struct LaTeXView: View {
    let content: String
    @State private var contentHeight: CGFloat = 120
    private let fontSize = 20.0

    var body: some View {
        MathJaxWebView(
            content: content,
            fontSize: fontSize,
            contentHeight: $contentHeight
        )
        .frame(height: max(contentHeight, 44))
        .frame(maxWidth: .infinity)
    }
}
```

數學字體固定為 20 pt，WebView 會將公式實際高度回傳給 SwiftUI，題目卡與選項框會隨內容自動增高，避免公式被裁切。

## 離線顯示

MathJax JavaScript 與 1,000 題題庫皆放在 App Bundle 中。

```swift
webView.loadHTMLString(
    MathJaxHTML.document(for: content, fontSize: fontSize),
    baseURL: Bundle.main.resourceURL
)
```

HTML 的 Content Security Policy 也限制只能載入 App 內的資源，因此題目可立即顯示，不會等待網路。

## 畫面功能

### 大廳

- 顯示 App 名稱與微積分圖示。
- 顯示 1,000 題、11 個主題與四個選項。
- 按下 Start Random Challenge 隨機抽題。

### 答題畫面

- 顯示題型與難度。
- 使用英文與 LaTeX 顯示完整題目。
- 提供四個選項，整個選項框皆可點擊。
- 作答後以綠色與紅色表示正確或錯誤。
- 可顯示或隱藏答案與詳細解法。
- 按下 Draw Another 可抽取另一題並自動捲回頁面頂端。
- 按下 Lobby 可返回大廳。

### 視覺設計

- 採用黑色深色風格。
- 一般英文文字使用襯線字體。
- 數學公式固定為 20 pt。
- 使用卡片、圓角、漸層與 SF Symbols 增加視覺辨識度。
- 支援公式雙指放大縮小，卡片高度會配合內容調整。

## 學習成果

透過這個 App，我練習了 SwiftUI 畫面配置、資料型別、Array、隨機抽樣、狀態管理、`ForEach`、按鈕事件、條件式畫面、動畫，以及使用 WKWebView 顯示 LaTeX 數學公式。除了達成隨機 App 的基本要求，也加入完整題庫、選擇題判定、詳細解答與離線顯示等功能。
