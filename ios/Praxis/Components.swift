#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

/// Dismisses the keyboard on taps outside text inputs without blocking controls.
struct KeyboardDismissOnTap: UIViewRepresentable {
    func makeUIView(context: Context) -> KeyboardDismissView { KeyboardDismissView() }
    func updateUIView(_ uiView: KeyboardDismissView, context: Context) {}

    static func dismantleUIView(_ uiView: KeyboardDismissView, coordinator: ()) {
        uiView.detach()
    }
}

final class KeyboardDismissView: UIView, UIGestureRecognizerDelegate {
    private weak var attachedWindow: UIWindow?
    private lazy var tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))

    override func didMoveToWindow() {
        super.didMoveToWindow()
        detach()
        guard let window else { return }
        tap.cancelsTouchesInView = false
        tap.delegate = self
        window.addGestureRecognizer(tap)
        attachedWindow = window
    }

    func detach() {
        attachedWindow?.removeGestureRecognizer(tap)
        attachedWindow = nil
    }

    @objc private func dismissKeyboard() {
        attachedWindow?.endEditing(true)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UITextField || current is UITextView { return false }
            view = current.superview
        }
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
}

/// The primary action treatment, adapted from the shared web button.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PraxisFont.body(.subheadline, weight: .semibold))
            .frame(maxWidth: .infinity, minHeight: RefTokens.Sizing.touchTarget)
            .padding(.horizontal, RefTokens.Spacing.s4)
            .foregroundStyle(SystemTokens.Colors.primaryForeground)
            .background(SystemTokens.Colors.accent, in: RoundedRectangle(cornerRadius: RefTokens.Radius.md, style: .continuous))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.5)
    }
}

/// A reusable typographic cover for a text or publication.
struct BookCover: View {
    let title: String
    var compact = true
    var imprint = "MIA"

    private var tone: Color {
        let seed = title.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff }
        return [SystemTokens.Colors.coverOchre, SystemTokens.Colors.coverRust,
                SystemTokens.Colors.coverOlive, SystemTokens.Colors.coverBlue][seed % 4]
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                tone
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle().fill(.white.opacity(0.72)).frame(width: proxy.size.width * 0.28, height: 2)
                    Spacer(minLength: 6)
                    Text(title)
                        .font(PraxisFont.fixed(compact ? RefTokens.Typography.bookCoverTitleCompact : RefTokens.Typography.bookCoverTitle,
                                               weight: .semibold, heading: true))
                        .lineLimit(compact ? 4 : 5).minimumScaleFactor(0.75).foregroundStyle(.white)
                    Spacer(minLength: 5)
                    Text(imprint).font(.system(size: RefTokens.Typography.bookCoverBrand, weight: .bold, design: .rounded))
                        .tracking(1.2).foregroundStyle(.white.opacity(0.8))
                }
                .padding(compact ? 7 : 9)
            }
            .clipShape(RoundedRectangle(cornerRadius: RefTokens.Radius.sm, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: RefTokens.Radius.sm, style: .continuous)
                .stroke(.black.opacity(RefTokens.Opacity.coverOutline), lineWidth: 1))
            .shadow(color: .black.opacity(RefTokens.Opacity.coverShadow), radius: RefTokens.Shadow.coverRadius,
                    x: 0, y: RefTokens.Shadow.coverOffsetY)
        }
    }
}

/// A generic list label. Place inside a native NavigationLink for interaction semantics.
struct ListRow: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: RefTokens.Spacing.s1) {
            Text(title).font(PraxisFont.heading(.headline, weight: .medium))
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle).font(PraxisFont.body(.subheadline)).foregroundStyle(SystemTokens.Colors.textSecondary)
            }
        }
        .padding(.vertical, RefTokens.Spacing.s1)
        .frame(minHeight: RefTokens.Sizing.touchTarget, alignment: .leading)
    }
}

/// Adds the platform glass surface on supported systems and a material fallback elsewhere.
struct GlassSurface: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content.background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(SystemTokens.Colors.separator.opacity(0.5), lineWidth: 1))
        }
    }
}

#endif
