import SwiftUI

struct NewCommandKeyboardShortcutView: View {
  @ObserveInjection var inject
  @Binding var payload: NewCommandPayload
  @Binding var validation: NewCommandView.Validation

  init(_ payload: Binding<NewCommandPayload>, validation: Binding<NewCommandView.Validation>) {
    _payload = payload
    _validation = validation
  }

  var body: some View {
    VStack {
      HStack {
        Label(title: { Text("Keyboard Shortcut:") }, icon: { EmptyView() })
          .labelStyle(HeaderLabelStyle())
        Spacer()
      }
    }
    .enableInjection()
  }
}

//struct NewCommandKeyboardShortcutView_Previews: PreviewProvider {
//  static var previews: some View {
//    NewCommandKeyboardShortcutView()
//  }
//}
