import Foundation

@MainActor
@Observable
final class ScreenLockPresenter {
    var isPresented = false

    func present() {
        isPresented = true
    }

    func dismiss() {
        isPresented = false
    }
}
