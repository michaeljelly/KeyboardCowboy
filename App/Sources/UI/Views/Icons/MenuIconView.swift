import Inject
import SwiftUI

struct MenuIconView: View {
  @ObserveInjection var inject
  let size: CGFloat
  @Binding var stacked: Bool

  var body: some View {
    Rectangle()
      .fill(
        LinearGradient(
          stops: [
            .init(color: Color(nsColor:  NSColor(red:0.95, green:0.70, blue:0.25, alpha:1.00)), location: 0.0),
            .init(color: Color(.controlAccentColor).opacity(0.65), location: 1.0),
          ],
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .overlay(alignment: .top) {
        Rectangle()
          .fill(Color(.white).opacity(0.4))
          .frame(height: size * 0.225)
          .overlay(alignment: .leading) {
            HStack(spacing: size * 0.06) {
              Image(systemName: "apple.logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(.black)
                .frame(height: size * 0.125)
              Text("App")
                .redacted(reason: .placeholder)
              Text("Files")
                .redacted(reason: .placeholder)
            }
            .font(
              Font.system(
                size: size * 0.125,
                design: .rounded
              )
            )
            .foregroundStyle(.black)
            .padding(.leading, size * 0.0_7)
          }
      }
      .overlay(alignment: .bottomTrailing) {
        Rectangle()
          .opacity(0.8)
          .frame(width: size * 0.8, height: size * 0.6)
          .clipShape(TopLeadingRoundedShape(radius: size * 0.0_9))
          .overlay(alignment: .topLeading) {
            windowControls()
              .padding(.leading, 2)
          }
          .compositingGroup()
          .shadow(radius: 3, y: 3)
      }
      .overlay(alignment: .bottomTrailing) {
        Rectangle()
          .fill(Color(.controlAccentColor).opacity(0.6))
          .frame(width: size * 0.75, height: size * 0.25)
          .clipShape(TopLeadingRoundedShape(radius: size * 0.0_5))
      }
      .background(Color(.systemGray))
      .compositingGroup()
      .clipShape(RoundedRectangle(cornerRadius: size * 0.125))
      .frame(width: size, height: size, alignment: .center)
      .fixedSize()
      .stacked($stacked, color: Color(.systemBlue), size: size)
      .enableInjection()
  }

  func windowControls() -> some View {
    HStack(spacing: size * 0.0_55) {
      Circle()
        .fill(
          LinearGradient(stops: [
            .init(color: Color(nsColor: NSColor(red:0.88, green:0.19, blue:0.14, alpha:1.00)), location: 0.1),
            .init(color: Color(.systemRed), location: 1)
          ],
                         startPoint: .top,
                         endPoint: .bottom)
        )
        .frame(height: size * 0.125)
      Circle()
        .fill(
          LinearGradient(colors: [
            Color(nsColor: NSColor(red:1.00, green:0.98, blue:0.37, alpha:1.00)),
            Color(.systemYellow)
          ], startPoint: .top, endPoint: .bottom)
          
        )
        .frame(height: size * 0.125)
      Circle()
        .fill(
          LinearGradient(colors: [
            Color(nsColor: NSColor(red:0.44, green:0.94, blue:0.39, alpha:1.00)),
            Color(.systemGreen)
          ], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .frame(height: size * 0.125)
    }
    .compositingGroup()
    .shadow(radius: size * 0.0_05, y: 1)
    .fontWeight(.bold)
    .padding([.top, .leading, .trailing], size * 0.0_5)
    .frame(height: size * 0.25)
  }
}

struct TopLeadingRoundedShape: Shape {
  var radius: CGFloat

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let topRight = CGPoint(x: rect.maxX, y: rect.minY)
    let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
    let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)

    path.move(to: bottomLeft)
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
    path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(270),
                clockwise: false)
    path.addLine(to: topRight)
    path.addLine(to: bottomRight)
    path.addLine(to: bottomLeft)

    return path
  }
}

#Preview {
  VStack {
    HStack {
      MenuIconView(size: 128, stacked: .constant(false))
      MenuIconView(size: 64, stacked: .constant(false))
      MenuIconView(size: 32, stacked: .constant(false))
    }
  }
    .padding()
}
