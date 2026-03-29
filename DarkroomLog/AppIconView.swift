import SwiftUI

struct AppIconView: View {
    var size: CGFloat = 400

    var body: some View {
        ZStack {
            // Background
            RadialGradient(
                colors: [Color(red: 0.10, green: 0.04, blue: 0.03),
                         Color(red: 0.03, green: 0.015, blue: 0.01)],
                center: UnitPoint(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: size * 0.7
            )

            // Ambient glow
            Ellipse()
                .fill(Color(red: 0.75, green: 0.13, blue: 0.04).opacity(0.13))
                .frame(width: size * 0.62, height: size * 0.82)
                .offset(y: -size * 0.03)

            // Light beam (cone)
            BeamShape()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.75, green: 0.13, blue: 0.04).opacity(0.22),
                                 Color(red: 0.75, green: 0.13, blue: 0.04).opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.65, height: size * 0.54)
                .offset(y: size * 0.10)

            // Easel base
            RoundedRectangle(cornerRadius: size * 0.008)
                .fill(Color(red: 0.12, green: 0.05, blue: 0.04))
                .frame(width: size * 0.76, height: size * 0.026)
                .offset(y: size * 0.305)

            // Photo print
            RoundedRectangle(cornerRadius: size * 0.012)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.91, green: 0.87, blue: 0.82),
                                 Color(red: 0.78, green: 0.74, blue: 0.69)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.54, height: size * 0.138)
                .offset(y: size * 0.243)

            // Print image area
            RoundedRectangle(cornerRadius: size * 0.006)
                .fill(Color(red: 0.72, green: 0.65, blue: 0.58).opacity(0.55))
                .frame(width: size * 0.46, height: size * 0.094)
                .offset(y: size * 0.243)

            // Enlarger head body
            RoundedRectangle(cornerRadius: size * 0.022)
                .fill(Color(red: 0.22, green: 0.08, blue: 0.06))
                .frame(width: size * 0.52, height: size * 0.092)
                .offset(y: -size * 0.34)

            // Enlarger head highlight
            RoundedRectangle(cornerRadius: size * 0.018)
                .fill(Color(red: 0.28, green: 0.11, blue: 0.08))
                .frame(width: size * 0.42, height: size * 0.072)
                .offset(y: -size * 0.34)

            // Lens housing
            Circle()
                .fill(Color(red: 0.12, green: 0.045, blue: 0.03))
                .frame(width: size * 0.14)
                .offset(y: -size * 0.34)
            Circle()
                .fill(Color(red: 0.18, green: 0.07, blue: 0.05))
                .frame(width: size * 0.10)
                .offset(y: -size * 0.34)
            Circle()
                .fill(Color(red: 0.55, green: 0.10, blue: 0.04).opacity(0.9))
                .frame(width: size * 0.065)
                .offset(y: -size * 0.34)
            Circle()
                .fill(Color(red: 0.82, green: 0.19, blue: 0.09).opacity(0.85))
                .frame(width: size * 0.036)
                .offset(y: -size * 0.34)

            // Column / bellows
            RoundedRectangle(cornerRadius: size * 0.008)
                .fill(Color(red: 0.14, green: 0.05, blue: 0.03))
                .frame(width: size * 0.048, height: size * 0.082)
                .offset(y: -size * 0.415)

            // Safelight — top right
            Circle()
                .fill(Color(red: 0.54, green: 0.04, blue: 0.01))
                .frame(width: size * 0.16)
                .offset(x: size * 0.30, y: -size * 0.30)
            Circle()
                .fill(Color(red: 0.75, green: 0.09, blue: 0.03).opacity(0.9))
                .frame(width: size * 0.115)
                .offset(x: size * 0.30, y: -size * 0.30)
            Circle()
                .fill(Color(red: 0.91, green: 0.19, blue: 0.09))
                .frame(width: size * 0.075)
                .offset(x: size * 0.30, y: -size * 0.30)
            Circle()
                .fill(Color(red: 1.0, green: 0.50, blue: 0.38).opacity(0.5))
                .frame(width: size * 0.028)
                .offset(x: size * 0.285, y: -size * 0.315)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.224))
    }
}

private struct BeamShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let topW = rect.width * 0.10
        let cx = rect.midX
        p.move(to: CGPoint(x: cx - topW, y: rect.minY))
        p.addLine(to: CGPoint(x: cx + topW, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        VStack(spacing: 24) {
            AppIconView(size: 300)
            HStack(spacing: 16) {
                AppIconView(size: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                AppIconView(size: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                AppIconView(size: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 9))
            }
        }
    }
}
