import SwiftUI

struct PowerCluster: View {
    @Environment(AppEnvironment.self) private var app
    @Binding var isLockArmed: Bool

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let powerSize = width * 0.45

            ZStack {
                Button(action: app.session.togglePower) {
                    Image(app.session.isPlaying ? "ic_off" : "ic_on")
                        .resizable()
                        .scaledToFit()
                        .frame(width: powerSize)
                }
                .position(x: width / 2, y: height / 2)
                .accessibilityLabel(app.session.isPlaying ? "Stop sound" : "Play sound")

                Button {
                    isLockArmed.toggle()
                    app.screenLock.present()
                } label: {
                    Image(isLockArmed ? "ic_off_lock" : "ic_on_lock")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width * 0.18)
                }
                .position(x: width / 2 + powerSize / 2 + width * 0.10, y: height / 2)
                .accessibilityLabel("Screen lock")
            }
        }
        .frame(height: 200)
    }
}
