import SwiftUI

struct MouseIconView: View {
  let size: CGFloat
  var body: some View {
    Rectangle()
      .fill(Color(.systemGreen))
      .overlay {
        AngularGradient(stops: [
          .init(color: Color.clear, location: 0.0),
          .init(color: Color.white.opacity(0.2), location: 0.2),
          .init(color: Color.clear, location: 1.0),
        ], center: .bottomLeading)

        LinearGradient(stops: [
          .init(color: Color.white.opacity(0.2), location: 0),
          .init(color: Color.clear, location: 0.3),
        ], startPoint: .top, endPoint: .bottom)

        LinearGradient(stops: [
          .init(color: Color.clear, location: 0.8),
          .init(color: Color(.windowBackgroundColor).opacity(0.3), location: 1.0),
        ], startPoint: .top, endPoint: .bottom)

        Capsule()
          .fill(Color(.white))
          .frame(width: size * 0.45, height: size * 0.8)
          .shadow(radius: 2, y: 2)
      }
      .overlay(alignment: .top) {
        Capsule()
          .fill(
            Color(.systemGray)
          )
          .overlay {
            LinearGradient(stops: [
              .init(color: Color.white.opacity(0.0), location: 0),
              .init(color: Color.white.opacity(0.5), location: 0.5),
              .init(color: Color.clear, location: 1.0),
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
          }
          .frame(width: size * 0.03, height: size * 0.04)
          .offset(y: size * 0.23)
      }
      .frame(width: size, height: size)
      .fixedSize()
      .iconShape(size)
  }
}

#Preview {
  HStack(alignment: .top, spacing: 8) {
    MouseIconView(size: 192)
    VStack(alignment: .leading, spacing: 8) {
      MouseIconView(size: 128)
      HStack(alignment: .top, spacing: 8) {
        MouseIconView(size: 64)
        MouseIconView(size: 32)
        MouseIconView(size: 16)
      }
    }
  }
  .padding()
}
