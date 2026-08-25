import SwiftUI

struct ScreenLockCover: View {
    @Binding var isPresented: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dragOffset: CGFloat = 0
    @State private var isCompletingUnlock = false
    private let unlockThreshold: CGFloat = -120
    private let completionDuration = 0.24

    var body: some View {
        if isPresented {
            ZStack {
                FrostedScrim()
                    .ignoresSafeArea()

                GeometryReader { geometry in
                    lockSheet(in: geometry)
                        .ignoresSafeArea(edges: .bottom)
                        .offset(y: dragOffset)
                        .contentShape(Rectangle())
                        .allowsHitTesting(!isCompletingUnlock)
                        .gesture(unlockGesture(screenHeight: geometry.size.height))
                }
            }
            .transition(.opacity)
            .onAppear {
                dragOffset = 0
                isCompletingUnlock = false
            }
        }
    }

    private func lockSheet(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: geometry.size.height * 0.18)

            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))

                    Text("Swipe up to unlock")
                        .font(AppTypography.bold(18))
                        .foregroundColor(.white)
                }

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 180, height: 180)
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        .frame(width: 180, height: 180)
                    Image("ic_unlock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 132, height: 132)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.bottom, 52)
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,
                        AppPalette.overlayScrim.opacity(0.35),
                        AppPalette.overlayScrim.opacity(0.78),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func unlockGesture(screenHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard !isCompletingUnlock else { return }
                dragOffset = min(value.translation.height, 0)
            }
            .onEnded { value in
                guard !isCompletingUnlock else { return }

                let movedFarEnough = value.translation.height < unlockThreshold
                let flickedUpward = value.predictedEndTranslation.height < unlockThreshold * 1.45

                if movedFarEnough || flickedUpward {
                    completeUnlock(screenHeight: screenHeight)
                } else {
                    withAnimation(.spring(duration: 0.24, bounce: 0)) {
                        dragOffset = 0
                    }
                }
            }
    }

    private func completeUnlock(screenHeight: CGFloat) {
        isCompletingUnlock = true

        if reduceMotion {
            isPresented = false
            resetGestureState()
            return
        }

        withAnimation(
            .timingCurve(0.23, 1, 0.32, 1, duration: completionDuration)
        ) {
            dragOffset = -screenHeight - 40
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + completionDuration) {
            isPresented = false
            resetGestureState()
        }
    }

    private func resetGestureState() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dragOffset = 0
            isCompletingUnlock = false
        }
    }
}
