import SwiftUI

struct FullWidthButtonStyle: PrimitiveButtonStyle {
    var tintColor: Color = .blue
    
    func makeBody(configuration: Configuration) -> some View {
        Button(action: { configuration.trigger() }) {
            configuration.label
                .frame(maxWidth: .infinity)
                .font(.body).bold()
        }
        .buttonStyle(.borderedProminent)
        .tint(tintColor)
        .controlSize(.large)
        .safeAreaPadding()
    }
}

extension PrimitiveButtonStyle where Self == FullWidthButtonStyle {
    static func fullWidth(tint: Color = .blue) -> Self {
        // Instantiate the style, which is Self in this context
        Self(tintColor: tint) 
    }
}
