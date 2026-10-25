import Foundation
import SwiftUI
import WebKit

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
            .accessibilityLabel(content)
    }
}

#if os(macOS)
private struct MathJaxWebView: NSViewRepresentable {
    let content: String
    let fontSize: Double
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> MathJaxCoordinator {
        MathJaxCoordinator(contentHeight: $contentHeight)
    }

    func makeNSView(context: Context) -> WKWebView {
        let webView = configuredWebView(coordinator: context.coordinator)
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = true
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        load(content, fontSize: fontSize, in: webView, coordinator: context.coordinator)
    }

    static func dismantleNSView(
        _ webView: WKWebView,
        coordinator: MathJaxCoordinator
    ) {
        removeHeightHandler(from: webView)
    }
}
#else
private struct MathJaxWebView: UIViewRepresentable {
    let content: String
    let fontSize: Double
    @Binding var contentHeight: CGFloat

    func makeCoordinator() -> MathJaxCoordinator {
        MathJaxCoordinator(contentHeight: $contentHeight)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = configuredWebView(coordinator: context.coordinator)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = false
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.maximumZoomScale = 4
        webView.scrollView.pinchGestureRecognizer?.isEnabled = true
        context.coordinator.observeZoom(in: webView.scrollView)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        load(content, fontSize: fontSize, in: webView, coordinator: context.coordinator)
    }

    static func dismantleUIView(
        _ webView: WKWebView,
        coordinator: MathJaxCoordinator
    ) {
        coordinator.stopObservingZoom()
        removeHeightHandler(from: webView)
    }
}
#endif

private func configuredWebView(coordinator: MathJaxCoordinator) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.userContentController.add(
        coordinator,
        name: MathJaxCoordinator.heightMessageName
    )

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = coordinator
    return webView
}

private func load(
    _ content: String,
    fontSize: Double,
    in webView: WKWebView,
    coordinator: MathJaxCoordinator
) {
    guard coordinator.loadedContent != content || coordinator.loadedFontSize != fontSize else {
        return
    }

    if coordinator.loadedContent == nil {
        coordinator.loadedContent = content
        coordinator.loadedFontSize = fontSize
        webView.loadHTMLString(
            MathJaxHTML.document(for: content, fontSize: fontSize),
            baseURL: Bundle.main.resourceURL
        )
    } else {
        coordinator.loadedContent = content
        coordinator.loadedFontSize = fontSize
        #if !os(macOS)
        webView.scrollView.setZoomScale(1, animated: false)
        #endif
        update(content, fontSize: fontSize, in: webView)
    }
}

private func update(_ content: String, fontSize: Double, in webView: WKWebView) {
    guard
        let encoded = try? JSONEncoder().encode(content),
        let javaScriptString = String(data: encoded, encoding: .utf8)
    else {
        return
    }

    let script = """
    document.body.classList.remove('math-ready');
    MathJax.typesetClear([document.body]);
    document.body.textContent = \(javaScriptString);
    document.body.style.fontSize = '\(fontSize)px';
    MathJax.typesetPromise([document.body]).then(() => {
      document.body.classList.add('math-ready');
      baseContentHeight = 0;
      reportHeight(true);
    });
    """
    webView.evaluateJavaScript(script)
}

private func removeHeightHandler(from webView: WKWebView) {
    webView.configuration.userContentController.removeScriptMessageHandler(
        forName: MathJaxCoordinator.heightMessageName
    )
}

private enum MathJaxHTML {
    private static let mathJaxSource: String = {
        guard
            let url = Bundle.main.url(forResource: "mathjax-tex-svg", withExtension: "js"),
            let source = try? String(contentsOf: url, encoding: .utf8)
        else {
            return ""
        }
        return source
    }()

    static func document(for content: String, fontSize: Double) -> String {
        let escapedContent = content
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")

        return """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=4, user-scalable=yes">
          <script>
            let baseContentHeight = 0;
            function reportHeight(recalculate = false) {
              setTimeout(function() {
                if (recalculate || baseContentHeight === 0) {
                  baseContentHeight = Math.ceil(document.body.scrollHeight);
                }
                window.webkit.messageHandlers.heightChanged.postMessage(baseContentHeight);
              }, 40);
            }
            window.MathJax = {
              tex: {
                inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
                displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']]
              },
              svg: { fontCache: 'local' },
              startup: {
                pageReady: () => MathJax.startup.defaultPageReady().then(() => {
                  document.body.classList.add('math-ready');
                  reportHeight(true);
                })
              }
            };
          </script>
          <script>\(mathJaxSource)</script>
          <style>
            :root { color-scheme: dark; }
            html, body {
              margin: 0;
              padding: 0;
              width: 100%;
              overflow: hidden;
              background: transparent;
            }
            body {
              box-sizing: border-box;
              padding: 4px 2px 8px;
              color: #f5f5f7;
              font: \(fontSize)px "Times New Roman", Times, serif;
              line-height: 1.65;
              white-space: pre-wrap;
              overflow-wrap: anywhere;
            }
            mjx-container[display="true"] {
              overflow: visible;
              padding: 6px 0;
              margin: 8px 0 !important;
            }
            mjx-container[display="true"] > svg {
              max-width: 100% !important;
              height: auto !important;
            }
          </style>
        </head>
        <body>\(escapedContent)</body>
        </html>
        """
    }
}

private final class MathJaxCoordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    static let heightMessageName = "heightChanged"

    @Binding var contentHeight: CGFloat
    var loadedContent: String?
    var loadedFontSize: Double?
    private var baseContentHeight: CGFloat = 120

    #if !os(macOS)
    private weak var observedScrollView: UIScrollView?
    #endif

    init(contentHeight: Binding<CGFloat>) {
        _contentHeight = contentHeight
    }

    #if !os(macOS)
    func observeZoom(in scrollView: UIScrollView) {
        observedScrollView = scrollView
        scrollView.pinchGestureRecognizer?.addTarget(
            self,
            action: #selector(handleZoomGesture)
        )
    }

    func stopObservingZoom() {
        observedScrollView?.pinchGestureRecognizer?.removeTarget(
            self,
            action: #selector(handleZoomGesture)
        )
        observedScrollView = nil
    }

    @objc private func handleZoomGesture() {
        updateScaledHeight()
    }

    private func updateScaledHeight() {
        let zoomScale = max(observedScrollView?.zoomScale ?? 1, 1)
        contentHeight = max(baseContentHeight * zoomScale, 44)
    }
    #endif

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard message.name == Self.heightMessageName else {
            return
        }

        guard let height = message.body as? Double else { return }

        baseContentHeight = CGFloat(height)
        #if os(macOS)
        contentHeight = max(baseContentHeight, 44)
        #else
        updateScaledHeight()
        #endif
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        webView.evaluateJavaScript("reportHeight()")
    }
}
