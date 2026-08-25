import SwiftUI

enum AppTypography {
    static func heavy(_ size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        .custom("SFProDisplay-Heavy", size: size, relativeTo: textStyle)
    }

    static func bold(_ size: CGFloat) -> Font {
        .custom("SFProDisplay-Bold", size: size)
    }

    static func medium(_ size: CGFloat) -> Font {
        .custom("SFProDisplay-Medium", size: size)
    }

    static func regular(_ size: CGFloat) -> Font {
        .custom("SFProDisplay-Regular", size: size)
    }
}
