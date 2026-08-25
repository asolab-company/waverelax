import SwiftUI

struct AppShellView: View {
    @Environment(AppEnvironment.self) private var app
    @State private var selectedTab: AppTab = .studio

    var body: some View {
        @Bindable var paywall = app.paywall
        @Bindable var lock = app.screenLock

        ZStack(alignment: .bottom) {
            switch selectedTab {
            case .library:
                ModeLibraryScreen()
            case .settings:
                SettingsScreen()
            case .studio:
                StudioScreen()
            }

            FloatingDockBar(selectedTab: $selectedTab)

            ScreenLockCover(isPresented: $lock.isPresented)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .zIndex(10)
        }
        .navigationBarBackButtonHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $paywall.isPresented) {
            PaywallScreen()
                .environment(app)
        }
    }
}
