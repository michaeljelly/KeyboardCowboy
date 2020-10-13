import SwiftUI
import ModelKit

struct KeyboardShortcutView: View {
  @Binding var keyboardShortcut: ModelKit.KeyboardShortcut?

  var body: some View {
    Recorder(keyboardShortcut: $keyboardShortcut)
  }
}

// MARK: - Previews

struct KeyboardShortcutView_Previews: PreviewProvider, TestPreviewProvider {
  static var previews: some View {
    testPreview.previewAllColorSchemes()
  }

  static var testPreview: some View {
    KeyboardShortcutView(keyboardShortcut: .constant(ModelFactory().keyboardShortcuts().first!))
      .frame(width: 320)
  }
}
