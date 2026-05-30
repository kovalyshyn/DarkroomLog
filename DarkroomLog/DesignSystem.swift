import SwiftUI

// MARK: - Spacing scale
// Use these instead of ad-hoc literals so layout rhythm stays on a 4-pt grid.
enum DRSpacing {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 20
}

// MARK: - SF Symbol map (one source of truth per concept)
enum DRIcon {
    static let enlarger  = "viewfinder"
    static let lens      = "camera.aperture"
    static let paper     = "doc.plaintext"
    static let developer = "flask"        // chemistry / developer — was inconsistently "drop"
    static let film      = "film"
    static let camera    = "camera"
    static let prints    = "photo.stack"
}

// MARK: - Darkroom timer palette (full-screen red safelight mode)
enum DarkroomColor {
    static let timeActive    = Color(red: 1.0,  green: 0.08, blue: 0.0)
    static let timeIdle      = Color(red: 0.4,  green: 0.0,  blue: 0.0)
    static let stepName      = Color(red: 0.5,  green: 0.05, blue: 0.05)
    static let progressTrack = Color(red: 0.2,  green: 0.0,  blue: 0.0)
    static let progressFill  = Color(red: 0.85, green: 0.1,  blue: 0.0)
    static let actionActive  = Color(red: 0.7,  green: 0.2,  blue: 0.2)
    static let actionIdle    = Color(red: 0.3,  green: 0.05, blue: 0.05)
}

// MARK: - Share card palette (exported image; always dark by design)
enum ShareCardColor {
    static let background = Color(white: 0.07)
    static let hairline   = Color.white.opacity(0.08)
    static let title      = Color.white
    static let value      = Color.white.opacity(0.9)
    static let secondary  = Color.white.opacity(0.7)
    static let muted      = Color.white.opacity(0.45)
    static let label      = Color.white.opacity(0.35)
    static let icon       = Color.white.opacity(0.4)
    static let footnote   = Color.white.opacity(0.25)
    static let badgeFill  = Color.white.opacity(0.1)
    static let badgeText  = Color.white.opacity(0.6)
}

/// Font sizes for a share card, scaled for full vs compact (landscape) layouts.
struct ShareCardMetrics {
    var pad: CGFloat
    var title: CGFloat
    var body: CGFloat
    var tag: CGFloat
    var icon: CGFloat
    var gap: CGFloat

    static let full    = ShareCardMetrics(pad: 20, title: 22, body: 14, tag: 9, icon: 13, gap: 14)
    static let compact = ShareCardMetrics(pad: 14, title: 17, body: 12, tag: 8, icon: 11, gap: 10)
}

// MARK: - Reusable views

/// Capsule pill used for counts, statuses and tags. `tint == nil` → neutral
/// (primary text on a grey fill); a tint colours both text and fill.
struct BadgeView: View {
    let text: String
    var tint: Color? = nil

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, DRSpacing.s)
            .padding(.vertical, 2)
            .background((tint ?? .secondary).opacity(0.15))
            .foregroundStyle(tint ?? .primary)
            .clipShape(Capsule())
    }
}

/// Read-only star rating (1–3). For the editable control use `StarRatingView`.
struct StarRatingDisplay: View {
    let rating: Int
    var size: CGFloat = 10

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? Color.yellow : Color.secondary.opacity(0.35))
            }
        }
        .font(.system(size: size))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating \(rating) of 3")
    }
}

// MARK: - Share card building blocks (shared by Print & FilmRoll cards)

struct ShareCardRow: View {
    let icon: String
    let label: String
    let value: String
    var metrics: ShareCardMetrics = .full

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: metrics.icon))
                .foregroundStyle(ShareCardColor.icon)
                .frame(width: 18)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: metrics.tag, weight: .semibold))
                    .foregroundStyle(ShareCardColor.label)
                    .tracking(0.8)
                Text(value)
                    .font(.system(size: metrics.body))
                    .foregroundStyle(ShareCardColor.value)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ShareCardHairline: View {
    var body: some View {
        Rectangle().fill(ShareCardColor.hairline).frame(height: 1)
    }
}

struct ShareCardFooter: View {
    var body: some View {
        Text("Generated with DarkroomLog")
            .font(.system(size: 10))
            .foregroundStyle(ShareCardColor.footnote)
    }
}
