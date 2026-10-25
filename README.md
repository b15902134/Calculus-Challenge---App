# Calculus Challenge

An offline SwiftUI calculus practice app containing 1,000 advanced problems with detailed solutions.

## Features

- 1,000 single-variable and multivariable calculus problems
- Random multiple-choice challenges
- Detailed worked solutions
- Offline LaTeX rendering with bundled MathJax
- Topics including limits, derivatives, integrals, differential equations, series, polar calculus, and vector calculus

## Requirements

- Xcode with the latest supported iOS SDK
- macOS capable of running Xcode

## Import and run

1. Clone or download this repository.
2. Open `Untitled Project 3.xcodeproj` in Xcode.
3. Select an iPhone simulator or connected device.
4. Press **Run** (`Command-R`).

The question bank and MathJax runtime are included in the app bundle, so the app works without a network connection.

## Project structure

- `ContentView.swift` — app interface and challenge flow
- `DetailedQuestionBank.swift` — Markdown question-bank parser
- `Calculus_1000_Advanced_Detailed_Solutions.md` — complete question bank
- `LaTeXView.swift` — offline MathJax renderer
- `mathjax-tex-svg.js` — bundled MathJax distribution

## License

No license has been selected. All rights are reserved by the repository owner.
