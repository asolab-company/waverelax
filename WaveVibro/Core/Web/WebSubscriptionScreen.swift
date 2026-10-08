import SwiftUI
import WebKit

struct WaveWebSubscriptionScreen: View {
    let url: URL
    let onFailure: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppEnvironment.self) private var app
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: "#FEDCF1"), Color(hex: "#E9DFFA")],
                           startPoint: .top, endPoint: .bottom)
            SubscriptionWebView(url: url, onFailure: onFailure, onReturn: {
                Task {
                    await app.store.refreshWebSubscription()
                }
            })
        }
        .ignoresSafeArea(.container)
        .preferredColorScheme(.light)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            while !Task.isCancelled {
                await app.store.refreshWebSubscription()
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
            }
        }
    }
}
private struct SubscriptionWebView: UIViewRepresentable {
    let url: URL
    let onFailure: () -> Void
    let onReturn: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(origin: url, onFailure: onFailure, onReturn: onReturn) }
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.uiDelegate = context.coordinator
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        view.underPageBackgroundColor = UIColor(Color(hex: "#E9DFFA"))
        view.scrollView.contentInsetAdjustmentBehavior = .never
        view.load(URLRequest(url: url))
        return view
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.stopLoading()
        uiView.navigationDelegate = nil
        uiView.uiDelegate = nil
    }
    @MainActor final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let onFailure: () -> Void
        let onReturn: () -> Void
        let origin: URL
        init(origin: URL, onFailure: @escaping () -> Void, onReturn: @escaping () -> Void) {
            self.origin = origin
            self.onFailure = onFailure; self.onReturn = onReturn
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let returned = webView.url, returned.scheme == origin.scheme,
                  returned.host == origin.host, returned.port == origin.port else { return }
            if returned.path == "/install" { onReturn() }
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { failed(error) }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { failed(error) }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { onFailure() }
        private func failed(_ error: Error) {
            if (error as NSError).code != NSURLErrorCancelled { onFailure() }
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
            if url.scheme == "https" || url.absoluteString == "about:blank" { decisionHandler(.allow) }
            else { decisionHandler(.cancel) }
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if navigationResponse.isForMainFrame, let response = navigationResponse.response as? HTTPURLResponse, response.statusCode >= 400 {
                decisionHandler(.cancel)
                onFailure()
            } else { decisionHandler(.allow) }
        }
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil, navigationAction.request.url?.scheme == "https" { webView.load(navigationAction.request) }
            return nil
        }
    }
}
