# Calculus Challenge

An offline iPhone calculus practice app built with **SwiftUI**, featuring **1,000 advanced calculus questions** and detailed worked solutions.

一款以 SwiftUI 開發的離線微積分練習 App，收錄 1,000 道進階題目，並提供四選一挑戰與詳細解答。

## App Demo · 操作展示

<p align="center">
  <img src="assets/calculus-challenge-demo.gif" alt="Calculus Challenge iPhone app demonstration" width="300">
</p>

> A short recording of the iPhone app in action. / iPhone App 操作示範。

## Features · 主要功能

- **1,000 advanced problems** across single-variable and multivariable calculus
- **Random multiple-choice challenges**, with four answer choices per question
- **Detailed worked solutions** after answering
- **Offline LaTeX rendering** using bundled MathJax
- Covers limits, derivatives, integrals, differential equations, series, polar calculus, and vector calculus

## Requirements · 開發需求

- A Mac capable of running Xcode
- Xcode with an iOS SDK compatible with the project
- An iPhone simulator or a connected iPhone

## Run in Xcode · 執行方式

> **Repository status:** The currently published repository provides `Untitled Project 3.xcodeproj.zip`, but the complete Swift source tree and bundled assets are not visible as standalone files. The archive may contain only the Xcode project configuration. Before expecting a fresh clone to build, upload the **complete** Xcode project, including its app/source folder, question-bank resources, and local MathJax files.

After the full project has been uploaded:

1. Clone or download this repository.
2. Open `Untitled Project 3.xcodeproj` in Xcode (or the updated project file if renamed).
3. Choose an iPhone simulator or a connected device.
4. Press **⌘R** to build and run.

## Project files · 專案檔案

The app's README previously described these components; ensure they are included in the repository before advertising a ready-to-build source release:

- `ContentView.swift` — SwiftUI interface and challenge flow
- `DetailedQuestionBank.swift` — question-bank loading and parsing
- `LaTeXView.swift` — math expression display
- Calculus question-bank Markdown file(s) — questions, answers, and explanations
- Bundled MathJax JavaScript — offline formula rendering
- `.xcodeproj` and all required assets/resources

The repository also includes Markdown documents describing the app and the question catalog.

## License

No license has been selected. All rights are reserved by the repository owner.
