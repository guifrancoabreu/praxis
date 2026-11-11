#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI

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
                        .font(.system(size: compact ? RefTokens.Typography.bookCoverTitleCompact : RefTokens.Typography.bookCoverTitle,
                                      weight: .semibold, design: .serif))
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
            Text(title).font(.system(.headline, design: .serif, weight: .medium))
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle).font(.subheadline).foregroundStyle(SystemTokens.Colors.textSecondary)
            }
        }
        .padding(.vertical, RefTokens.Spacing.s1)
        .frame(minHeight: 44, alignment: .leading)
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
