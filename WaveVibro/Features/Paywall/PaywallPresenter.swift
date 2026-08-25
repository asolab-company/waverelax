import Foundation

@MainActor
@Observable
final class PaywallPresenter {
    var isPresented = false

    func present() {
        isPresented = true
    }

    func dismiss() {
        isPresented = false
    }
}
