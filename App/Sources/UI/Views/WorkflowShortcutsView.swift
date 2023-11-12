import SwiftUI
import Bonzai

struct WorkflowShortcutsView: View {
  @Binding private var data: [KeyShortcut]
  private var focus: FocusState<AppFocus?>.Binding
  private let onUpdate: ([KeyShortcut]) -> Void
  private let selectionManager: SelectionManager<KeyShortcut>

  init(_ focus: FocusState<AppFocus?>.Binding,
       data: Binding<[KeyShortcut]>,
       selectionManager: SelectionManager<KeyShortcut>,
       onUpdate: @escaping ([KeyShortcut]) -> Void) {
    _data = data
    self.focus = focus
    self.onUpdate = onUpdate
    self.selectionManager = selectionManager
  }

  var body: some View {
    EditableKeyboardShortcutsView<AppFocus>(focus,
                                            focusBinding: { .detail(.keyboardShortcut($0)) },
                                            keyboardShortcuts: $data,
                                            selectionManager: selectionManager,
                                            onTab: {
      if $0 {
        focus.wrappedValue = .detail(.commands)
      } else {
        focus.wrappedValue = .detail(.name)
      }
    })
      .frame(minHeight: 48, maxHeight: 48)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(.textBackgroundColor).opacity(0.65))
      )
      .padding(.vertical, 6)
      .onChange(of: data, perform: { newValue in
        onUpdate(newValue)
      })
      .focused(focus, equals: .detail(.keyboardShortcuts))
  }
}

struct WorkflowShortcutsView_Previews: PreviewProvider {
  @FocusState static var focus: AppFocus?
  static var previews: some View {
    WorkflowShortcutsView($focus,
                          data: .constant([]),
                          selectionManager: .init(),
                          onUpdate: {
      _ in
    })
      .designTime()
      .padding()
  }
}
