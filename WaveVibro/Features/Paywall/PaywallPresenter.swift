import Foundation

@MainActor
@Observable
final class PaywallPresenter {
    var isPresented = false
    private(set) var nativeOnly = false

    func present() {
        nativeOnly = false
        isPresented = true
    }

    func presentNative() {
        nativeOnly = true
        isPresented = true
    }

    func dismiss() {
        isPresented = false
    }
}
