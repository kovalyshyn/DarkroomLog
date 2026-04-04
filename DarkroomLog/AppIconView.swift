import SwiftUI

struct AppIconView: View {
    var size: CGFloat = 400

    var body: some View {
        Image("AppIconImage")
            .resizable()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.224))
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
