import SwiftUI

struct FloatingDockBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        ZStack {
            Color.white
                .frame(height: 80)
                .offset(y: 50)
                .ignoresSafeArea(.all, edges: .bottom)

            DockContour()
                .fill(Color.white)
                .frame(height: 80)
                .overlay(
                    HStack {
                        dockItem(tab: .library)
                        Spacer()
                        dockItem(tab: .settings)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 5)
                )

            Button {
                selectedTab = .studio
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.white, AppPalette.sheetBackground],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 76, height: 76)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                    Image(AppTab.studio.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .foregroundColor(
                            selectedTab == .studio
                                ? AppPalette.primary
                                : AppPalette.inactiveControl
                        )
                }
            }
            .accessibilityLabel(AppTab.studio.title)
            .offset(y: -40)
        }
        .frame(height: 70)
    }

    private func dockItem(tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        let color = isSelected ? AppPalette.primary : AppPalette.inactiveControl

        return Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(tab.iconName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 35, height: 35)
                    .foregroundColor(color)

                Text(tab.title)
                    .font(AppTypography.regular(12))
                    .foregroundColor(color)
            }
        }
        .accessibilityLabel(tab.title)
    }
}
